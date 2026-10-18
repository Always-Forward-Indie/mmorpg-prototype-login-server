#include "network/NetworkManager.hpp"
#include "utils/TimestampUtils.hpp"
#include <spdlog/logger.h>
#include <sstream>

struct Version {
    int major = 0;
    int minor = 0;
    int patch = 0;
};

static bool parseVersion(const std::string& s, Version& v)
{
    if (s.empty())
        return false;
    std::stringstream ss(s);
    std::string segment;
    if (!std::getline(ss, segment, '.'))
        return false;
    try { v.major = std::stoi(segment); } catch (...) { return false; }
    if (!std::getline(ss, segment, '.'))
        return false;
    try { v.minor = std::stoi(segment); } catch (...) { return false; }
    if (!std::getline(ss, segment, '.'))
        return false;
    try { v.patch = std::stoi(segment); } catch (...) { return false; }
    return true;
}

static int compareVersions(const Version& a, const Version& b)
{
    if (a.major != b.major) return a.major - b.major;
    if (a.minor != b.minor) return a.minor - b.minor;
    return a.patch - b.patch;
}

NetworkManager::NetworkManager(EventQueue &eventQueue, std::tuple<DatabaseConfig, LoginServerConfig> &configs, Logger &logger)
    : acceptor_(io_context_),
      logger_(logger),
      configs_(configs),
      jsonParser_(),
      eventQueue_(eventQueue)
{
    log_ = logger.getSystem("network");
    boost::system::error_code ec;

    // Get the custom port and IP address from the configs
    std::uint16_t customPort = std::get<1>(configs).port;
    std::string customIP = std::get<1>(configs).host;
    int maxClients = std::get<1>(configs).max_clients;

    // Create an endpoint with the custom IP and port
    boost::asio::ip::tcp::endpoint endpoint(boost::asio::ip::address::from_string(customIP), customPort);

    // Open the acceptor and bind it to the endpoint
    acceptor_.open(endpoint.protocol(), ec);
    if (!ec)
    {
        log_->info("Starting Login Server...");
        acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true), ec);
        acceptor_.bind(endpoint, ec);
        acceptor_.listen(maxClients, ec);
    }

    if (ec)
    {
        logger.logError("Error during server initialization: " + ec.message());
        return;
    }

    // Print IP address and port when the server starts
    log_->info("Login Server started on IP: " + customIP + ", Port: " + std::to_string(customPort));
}

void NetworkManager::startAccept()
{
    auto clientSocket = std::make_shared<boost::asio::ip::tcp::socket>(io_context_);

    acceptor_.async_accept(*clientSocket, [this, clientSocket](const boost::system::error_code &error)
                           {
                if (!error) {
                    // Get the Client remote endpoint (IP address and port)
                    boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint();
                    std::string clientIP = remoteEndpoint.address().to_string();
                    std::string portNumber = std::to_string(remoteEndpoint.port());

                    int maxClients = std::get<1>(configs_).max_clients;
                    {
                        std::lock_guard<std::mutex> lock(activeSocketsMutex_);
                        if (activeSockets_.size() >= static_cast<size_t>(maxClients))
                        {
                            log_->warn("Max clients reached (" + std::to_string(maxClients) +
                                       "), rejecting connection from " + clientIP + ":" + portNumber);
                            boost::system::error_code closeEc;
                            clientSocket->close(closeEc);
                            startAccept();
                            return;
                        }
                        activeSockets_.insert(clientSocket.get());
                    }

                    // Print the Client IP address
                    log_->info("New Client with IP: " + clientIP + " Port: " + portNumber + " - connected!");
                    
                    // Start reading data from the client
                    startReadingFromClient(clientSocket);
                }
                else{
                    log_->warn("Accept client connection error: " + error.message());
                }

                // Continue accepting new connections even if there's an error
                startAccept(); });
}

void NetworkManager::startIOEventLoop()
{
    log_->info("Starting Login Server IO Context...");

    startAccept();

    auto numThreads = std::thread::hardware_concurrency();
    for (size_t i = 0; i < numThreads; ++i)
    {
        threadPool_.emplace_back([this]()
                                 { io_context_.run(); });
    }
}

NetworkManager::~NetworkManager()
{
    log_->warn("Network Manager destructor is called...");
    acceptor_.close();
    io_context_.stop();
    for (auto &thread : threadPool_)
    {
        if (thread.joinable())
            thread.join();
    }
    // ASan-found UAF fix (same class as game/chunk): SocketWriteQueue holds
    // a strand bound to io_context_'s service, but writeQueues_ is declared
    // BEFORE io_context_ — clear here (threads joined, io alive) so strands
    // die before the service does.
    {
        std::lock_guard<std::mutex> lock(writeQueuesMutex_);
        writeQueues_.clear();
    }
}

void NetworkManager::handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket,
                                      const std::array<char, max_length> &dataBuffer,
                                      size_t bytes_transferred)
{
    // Per-connection accumulated buffer (thread-safe via mutex)
    std::string accumulatedData;
    {
        std::lock_guard<std::mutex> lock(socketBufferMutex_);
        auto it = socketBuffers_.find(clientSocket.get());
        if (it != socketBuffers_.end())
        {
            accumulatedData = std::move(it->second);
            it->second.clear();
        }
    }

    // Append new data to the accumulated buffer
    accumulatedData.append(dataBuffer.data(), bytes_transferred);

    // Check for the delimiter in the accumulated data
    std::string delimiter = "\n"; // Your chosen delimiter
    size_t delimiterPos;
    while ((delimiterPos = accumulatedData.find(delimiter)) != std::string::npos)
    { // Assuming '\n' is the delimiter
        // Extract one message up to the delimiter
        std::string message = accumulatedData.substr(0, delimiterPos);

        // debug-level: per-packet payload (very noisy with bots/swarm).
        log_->debug("Received data from Client: " + message);

        // Process the message
        processMessage(clientSocket, message);

        // Erase processed message and delimiter from the buffer
        accumulatedData.erase(0, delimiterPos + 1); // +1 to remove the delimiter as well
    }

    // Store any remaining partial message back into the per-socket buffer
    if (!accumulatedData.empty())
    {
        // DoS guard: a client that never sends '\n' must not grow memory unboundedly.
        if (accumulatedData.size() > protocol::kMaxAccumulatedBytes)
        {
            logger_.logError("Framing overflow (" + std::to_string(accumulatedData.size()) +
                             " bytes without newline), dropping buffer.");
            nlohmann::json err;
            err["header"]["eventType"] = "framing";
            err["header"]["message"] = protocol::kErrOversize;
            err["body"] = nlohmann::json::object();
            sendResponse(clientSocket, generateResponseMessage("error", err));
            accumulatedData.clear();
        }
        std::lock_guard<std::mutex> lock(socketBufferMutex_);
        socketBuffers_[clientSocket.get()] = std::move(accumulatedData);
    }
}

void NetworkManager::processMessage(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &message)
{
    // Framing: 8KB matches proto/mmo_proto.py. Oversize gets an explicit
    // ERR_OVERSIZE (previously silent drop => client hung until timeout).
    if (message.length() > protocol::kMaxMessageBytes)
    {
        logger_.logError("processMessage: message too large (" + std::to_string(message.length()) +
                         " bytes), max is " + std::to_string(protocol::kMaxMessageBytes) + ". Rejecting.");
        nlohmann::json err;
        // Best-effort eventType so the client can correlate the error.
        std::string eventType = "unknown";
        try {
            auto probe = nlohmann::json::parse(message.substr(0, 512), nullptr, false);
            if (!probe.is_discarded() && probe.contains("header") && probe["header"].is_object() &&
                probe["header"].contains("eventType") && probe["header"]["eventType"].is_string())
                eventType = probe["header"]["eventType"].get<std::string>();
        } catch (...) {}
        err["header"]["eventType"] = eventType;
        err["header"]["message"] = protocol::kErrOversize;
        err["body"] = nlohmann::json::object();
        sendResponse(clientSocket, generateResponseMessage("error", err));
        return;
    }

    // Single parse: the wire bytes are parsed once here and the json is
    // threaded through the extractors below (was 6-7 parses/message).
    // Malformed input throws -> outer catch replies ERR_MALFORMED (unchanged).
    try
    {
        const nlohmann::json jsonData = nlohmann::json::parse(message);
        // Parse the data received from the client using JSONParser
        std::string eventType = jsonParser_.parseEventType(jsonData);
        ClientDataStruct clientData = jsonParser_.parseClientData(jsonData);
        CharacterDataStruct characterData = jsonParser_.parseCharacterData(jsonData);
        PositionStruct positionData = jsonParser_.parsePositionData(jsonData);
        MessageStruct messageStruct = jsonParser_.parseMessage(jsonData);

        // Parse timestamps for lag compensation
        TimestampStruct timestamps = TimestampUtils::parseTimestampsFromHeader(jsonData);

        log_->debug("Event type: " + eventType);
        log_->debug("Client ID: " + std::to_string(clientData.clientId));
        log_->debug("Client hash: " + clientData.hash);
        log_->debug("Character ID: " + std::to_string(characterData.characterId));

        // Check if the type of request is authentificationClient
        if (eventType == "authentificationClient" && clientData.login != "" && clientData.password != "")
        {
            // Set the client data
            // characterData.characterPosition = positionData;
            // clientData.characterData = characterData;
            clientData.socket = clientSocket;

            // Version check — reject early if client version is outside [min, max]
            if (!checkClientVersion(clientData.clientVersion, eventType, clientSocket))
                return;

            // Create a new event where authentificate the client and push it to the queue
            Event authentificationClientEvent(Event::AUTH_CLIENT, clientData.clientId, clientData, clientSocket);
            authentificationClientEvent.setTimestamps(timestamps); // Add timestamps
            eventQueue_.push(authentificationClientEvent);
        }

        // Check if the type of request is getCharactersList
        if (eventType == "getCharactersList" && clientData.hash != "" && clientData.clientId != 0)
        {
            // Set the client data
            // characterData.characterPosition = positionData;
            // clientData.characterData = characterData;
            clientData.socket = clientSocket;

            // Create a new event where get characters list according client and push it to the queue
            Event getCharactersListEvent(Event::GET_CHARACTERS_LIST, clientData.clientId, clientData, clientSocket);
            getCharactersListEvent.setTimestamps(timestamps); // Add timestamps
            eventQueue_.push(getCharactersListEvent);
        }

        // Check if the type of request is createCharacter
        if (eventType == "createCharacter" && clientData.hash != "" && clientData.clientId != 0)
        {
            clientData.characterData = characterData;
            clientData.socket = clientSocket;

            Event createCharacterEvent(Event::CREATE_CHARACTER, clientData.clientId, clientData, clientSocket);
            createCharacterEvent.setTimestamps(timestamps);
            eventQueue_.push(createCharacterEvent);
        }

        // Check if the type of request is disconnectClient
        if (eventType == "disconnectClient" && clientData.hash != "" && clientData.clientId != 0)
        {
            // Create a new event where disconnect the client and push it to the queue
            Event disconnectClientEvent(Event::DISCONNECT_CLIENT, clientData.clientId, clientData, clientSocket);
            disconnectClientEvent.setTimestamps(timestamps); // Add timestamps
            eventQueue_.push(disconnectClientEvent);
        }

        // Check if the type of request is pingClient
        if (eventType == "pingClient")
        {
            clientData.socket = clientSocket;

            // Create a new event where ping the client and push it to the queue
            Event pingClientEvent(Event::PING_CLIENT, clientData.clientId, clientData, clientSocket);
            pingClientEvent.setTimestamps(timestamps); // Add timestamps
            eventQueue_.push(pingClientEvent);
        }

        // registerAccount — no auth required; supply registration IP from socket
        if (eventType == "registerAccount")
        {
            RegistrationDataStruct reg;
            reg.socket = clientSocket;
            reg.registrationIp = clientSocket->remote_endpoint().address().to_string();

            // Parse login/password/email from the already-parsed body.
            // Missing fields => downstream validation rejects with an error
            // response (no extra parse).
            if (jsonData.contains("body") && jsonData["body"].is_object())
            {
                const auto &body = jsonData["body"];
                if (body.contains("login") && body["login"].is_string())
                    reg.login = body["login"].get<std::string>();
                if (body.contains("password") && body["password"].is_string())
                    reg.password = body["password"].get<std::string>();
                if (body.contains("email") && body["email"].is_string())
                    reg.email = body["email"].get<std::string>();
                if (body.contains("clientVersion") && body["clientVersion"].is_string())
                    reg.clientVersion = body["clientVersion"].get<std::string>();
            }

            // Version check — reject early if client version is outside [min, max]
            if (!checkClientVersion(reg.clientVersion, eventType, clientSocket))
                return;

            Event registerEvent(Event::REGISTER_ACCOUNT, 0, reg, clientSocket);
            registerEvent.setTimestamps(timestamps);
            eventQueue_.push(registerEvent);
        }

        // getCharacterCreationOptions — requires valid session
        if (eventType == "getCharacterCreationOptions" && clientData.hash != "" && clientData.clientId != 0)
        {
            clientData.socket = clientSocket;
            Event optionsEvent(Event::GET_CHARACTER_CREATION_OPTIONS, clientData.clientId, clientData, clientSocket);
            optionsEvent.setTimestamps(timestamps);
            eventQueue_.push(optionsEvent);
        }

        // deleteCharacter — requires valid session + characterId
        if (eventType == "deleteCharacter" && clientData.hash != "" && clientData.clientId != 0)
        {
            clientData.characterData = characterData; // carries characterId
            clientData.socket = clientSocket;
            Event deleteCharEvent(Event::DELETE_CHARACTER, clientData.clientId, clientData, clientSocket);
            deleteCharEvent.setTimestamps(timestamps);
            eventQueue_.push(deleteCharEvent);
        }
    }
    catch (const std::exception &e)
    {
        // Malformed JSON previously vanished silently (client timeout).
        // Now: explicit ERR_MALFORMED so bots/clients fail fast with context.
        logger_.logError("processMessage error: " + std::string(e.what()), RED);
        try {
            nlohmann::json err;
            err["header"]["eventType"] = "unknown";
            err["header"]["message"] = protocol::kErrMalformed;
            err["body"] = nlohmann::json::object();
            sendResponse(clientSocket, generateResponseMessage("error", err));
        } catch (...) {}
    }
}

bool NetworkManager::checkClientVersion(const std::string &clientVersion, const std::string &eventType,
                                         std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket)
{
    const std::string &minVer = std::get<1>(configs_).minClientVersion;
    const std::string &maxVer = std::get<1>(configs_).maxClientVersion;

    Version client, vmin, vmax;
    const bool clientOk = parseVersion(clientVersion, client);
    const bool minOk = parseVersion(minVer, vmin);
    const bool maxOk = parseVersion(maxVer, vmax);

    if (!clientOk || !minOk || !maxOk || compareVersions(client, vmin) < 0)
    {
        const char *errorCode = "ERR_VERSION_OUTDATED";
        nlohmann::json err;
        err["header"]["eventType"] = eventType;
        err["header"]["message"] = errorCode;
        err["body"] = nlohmann::json::object();
        err["body"]["serverVersion"] = protocol::kProtocolVersion;
        err["body"]["minClientVersion"] = minVer;
        err["body"]["maxClientVersion"] = maxVer;
        sendResponse(clientSocket, generateResponseMessage("error", err));
        logger_.logError("Version mismatch: client=" + clientVersion +
                         " server_min=" + minVer + " server_max=" + maxVer);
        return false;
    }

    if (compareVersions(client, vmax) > 0)
    {
        const char *errorCode = "ERR_VERSION_TOO_NEW";
        nlohmann::json err;
        err["header"]["eventType"] = eventType;
        err["header"]["message"] = errorCode;
        err["body"] = nlohmann::json::object();
        err["body"]["serverVersion"] = protocol::kProtocolVersion;
        err["body"]["minClientVersion"] = minVer;
        err["body"]["maxClientVersion"] = maxVer;
        sendResponse(clientSocket, generateResponseMessage("error", err));
        logger_.logError("Version mismatch: client=" + clientVersion +
                         " server_min=" + minVer + " server_max=" + maxVer);
        return false;
    }

    return true;
}

void NetworkManager::sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &responseString)
{
    // CRITICAL-11 fix: responseString is a const-ref parameter; it may be destroyed before
    // async_write completes. Copy once into a shared_ptr to keep data alive until completion.
    // Wire-contract guard (seam with the UE client): the client parses one
    // '\n'-terminated JSON object per line with an 8KB cap. Anything bigger
    // is dropped client-side, so flag it here at warn level with the event
    // type instead of silently producing snapshot holes.
    constexpr size_t kClientLineCapWarnBytes = 6 * 1024;
    if (responseString.size() > kClientLineCapWarnBytes)
    {
        std::string eventType = "?";
        const std::string key = "\"eventType\":\"";
        const size_t pos = responseString.find(key);
        if (pos != std::string::npos)
        {
            const size_t begin = pos + key.size();
            const size_t end = responseString.find('"', begin);
            if (end != std::string::npos)
                eventType = responseString.substr(begin, end - begin);
        }
        log_->warn("Oversized packet for client wire ({} bytes, eventType={}): exceeds UE 8KB line cap — chunk the array payload",
            responseString.size(), eventType);
    }
    auto dataPtr = std::make_shared<const std::string>(responseString);
    enqueueWrite(std::move(clientSocket), std::move(dataPtr));
}

std::shared_ptr<NetworkManager::SocketWriteQueue>
NetworkManager::getOrCreateWriteQueue(
    const std::shared_ptr<boost::asio::ip::tcp::socket> &socket)
{
    if (!socket)
        return nullptr;
    boost::asio::ip::tcp::socket *key = socket.get();
    std::lock_guard<std::mutex> lock(writeQueuesMutex_);
    auto it = writeQueues_.find(key);
    if (it != writeQueues_.end())
    {
        // Same live object => same queue (one strand per socket, always:
        // concurrent async_write on one socket is UB in Asio).
        auto owner = it->second->owner.lock();
        if (owner && owner.get() == key)
            return it->second;
        // Otherwise REPLACE, never mutate in place: strand callbacks may
        // still reference the old queue object, and touching writing/queues
        // off-strand breaks the single-writer invariant (SEGV under churn).
        auto q = std::make_shared<SocketWriteQueue>(io_context_);
        q->owner = socket;
        it->second = q;
        return q;
    }
    auto q = std::make_shared<SocketWriteQueue>(io_context_);
    q->owner = socket;
    writeQueues_.emplace(key, q);
    return q;
}

void
NetworkManager::removeWriteQueue(boost::asio::ip::tcp::socket *key,
    const std::shared_ptr<boost::asio::ip::tcp::socket> &expectedOwner)
{
    // Erase-then-recreate for one live socket yields two strands writing it
    // (UB). So this only drops owner-expired entries now; live mappings are
    // reclaimed by gcWriteQueues().
    if (!key)
        return;
    std::lock_guard<std::mutex> lock(writeQueuesMutex_);
    auto it = writeQueues_.find(key);
    if (it == writeQueues_.end())
        return;
    if (expectedOwner)
    {
        auto owner = it->second->owner.lock();
        if (owner)
            return;
    }
    writeQueues_.erase(it);
}

void
NetworkManager::gcWriteQueues()
{
    std::lock_guard<std::mutex> lock(writeQueuesMutex_);
    for (auto it = writeQueues_.begin(); it != writeQueues_.end();)
    {
        // Owner expired => no posted strand lambda can reference the socket;
        // erasing the map entry is safe (no queue fields touched off-strand).
        if (it->second->owner.expired())
            it = writeQueues_.erase(it);
        else
            ++it;
    }
}

void
NetworkManager::enqueueWrite(std::shared_ptr<boost::asio::ip::tcp::socket> socket,
    std::shared_ptr<const std::string> data)
{
    auto queue = getOrCreateWriteQueue(socket);
    if (!queue)
        return;
    boost::asio::post(queue->strand,
        [this, socket = std::move(socket), queue, data = std::move(data)]() mutable
        {
            queue->pending.push_back(std::move(data));
            if (!queue->writing)
                doNextWrite(std::move(socket), std::move(queue));
        });
}

void
NetworkManager::doNextWrite(std::shared_ptr<boost::asio::ip::tcp::socket> socket,
    std::shared_ptr<SocketWriteQueue> queue)
{
    // Must be called on queue->strand.
    if (queue->pending.empty())
    {
        queue->writing = false;
        return;
    }
    std::shared_ptr<const std::string> data = std::move(queue->pending.front());
    queue->pending.pop_front();

    if (!socket || !socket->is_open())
    {
        queue->writing = false;
        queue->pending.clear();
        return;
    }

    queue->writing = true;
    boost::asio::async_write(*socket,
        boost::asio::buffer(*data),
        boost::asio::bind_executor(queue->strand,
            [this, socket, queue, data](const boost::system::error_code &error, size_t bytes_transferred) mutable
            {
                if (error)
                {
                    log_->error("Error during async_write: " + error.message());
                    queue->writing = false;
                    queue->pending.clear();
                    if (socket->is_open())
                    {
                        boost::system::error_code ec;
                        socket->close(ec);
                    }
                    return;
                }
                boost::system::error_code ec;
                boost::asio::ip::tcp::endpoint remoteEndpoint = socket->remote_endpoint(ec);
                if (!ec)
                {
                    log_->debug("Bytes send: " + std::to_string(bytes_transferred));
                    log_->debug("Data send successfully to the Client: " +
                                remoteEndpoint.address().to_string() + ", Port: " +
                                std::to_string(remoteEndpoint.port()));
                }
                doNextWrite(std::move(socket), std::move(queue));
            }));
}

void NetworkManager::reapSocket(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket)
{
    if (!clientSocket)
        return;
    {
        std::lock_guard<std::mutex> lock(socketBufferMutex_);
        socketBuffers_.erase(clientSocket.get());
    }
    {
        std::lock_guard<std::mutex> lock(activeSocketsMutex_);
        activeSockets_.erase(clientSocket.get());
    }
    // Owner-checked: a live re-registration at a reused address keeps its queue;
    // only owner-expired mappings are dropped (reclaimed by gcWriteQueues).
    removeWriteQueue(clientSocket.get(), clientSocket);
    boost::system::error_code closeEc;
    clientSocket->close(closeEc);
}

void NetworkManager::startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket)
{
    auto dataBufferClient = std::make_shared<std::array<char, max_length>>();
    std::fill(dataBufferClient->begin(), dataBufferClient->end(), 0); // Clear the buffer

    clientSocket->async_read_some(boost::asio::buffer(*dataBufferClient),
                                  [this, clientSocket, dataBufferClient](const boost::system::error_code &error, size_t bytes_transferred)
                                  {
                                      boost::system::error_code ec;
                                      boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(ec);
                                      if (!ec)
                                      {
                                          // Successfully retrieved the remote endpoint
                                          std::string ipAddress = remoteEndpoint.address().to_string();
                                          std::string portNumber = std::to_string(remoteEndpoint.port());

                                          log_->debug("Bytes received: " + std::to_string(bytes_transferred));
                                          log_->debug("Data received from Client IP address: " + ipAddress + ", Port: " + portNumber);
                                      }
                                      else
                                      {
                                          // Handle error
                                      }

                                      // start reading from the client
                                      if (!error)
                                      {
                                          // Data has been read successfully, handle it
                                          handleClientData(clientSocket, *dataBufferClient, bytes_transferred);
                                          // Immediately reschedule the next read. Read and write are fully
                                          // decoupled: sendResponse fires async_write independently.
                                          // This prevents the socket from stalling when no response is sent
                                          // (e.g. unknown event type, early-exit error path).
                                          startReadingFromClient(clientSocket);
                                      }
                                      else if (error == boost::asio::error::eof)
                                      {
                                          // The client has closed the connection
                                          log_->error("Client disconnected gracefully.");
                                          reapSocket(clientSocket);
                                      }
                                      else if (error == boost::asio::error::operation_aborted)
                                      {
                                          // The read operation was canceled, likely due to the client disconnecting
                                          log_->error("Read operation canceled (client disconnected).");
                                          reapSocket(clientSocket);
                                      }
                                      else
                                      {
                                          // Handle other errors
                                          log_->error("Error during async_read_some: " + error.message());
                                          reapSocket(clientSocket);
                                      }
                                  });
}

std::string NetworkManager::generateResponseMessage(const std::string &status, const nlohmann::json &message)
{
    nlohmann::json response;
    std::string currentTimestamp = TimestampUtils::getCurrentTimestamp();
    response["header"] = message["header"];
    response["header"]["status"] = status;
    response["header"]["timestamp"] = currentTimestamp;
    response["header"]["version"] = protocol::kProtocolVersion;
    response["body"] = message["body"];
    // Protocol: every error response carries a machine-readable
    // `body.errorCode` mirroring `header.message` (additive: old clients
    // ignore unknown body keys). Explicit errorCode set by a handler wins.
    if (status == "error" && response["header"].contains("message") &&
        response["header"]["message"].is_string() &&
        (!response["body"].is_object() || !response["body"].contains("errorCode")))
    {
        if (!response["body"].is_object())
            response["body"] = nlohmann::json::object();
        response["body"]["errorCode"] = response["header"]["message"];
    }

    std::string responseString = response.dump();

    log_->debug("Response generated: " + responseString);

    return responseString + "\n";
}

std::string NetworkManager::generateResponseMessage(const std::string &status, const nlohmann::json &message, const TimestampStruct &timestamps)
{
    nlohmann::json response;
    std::string currentTimestamp = TimestampUtils::getCurrentTimestamp();
    response["header"] = message["header"];
    response["header"]["status"] = status;
    response["header"]["timestamp"] = currentTimestamp;
    response["header"]["version"] = protocol::kProtocolVersion;

    // Add lag compensation timestamps to header
    TimestampStruct finalTimestamps = timestamps;
    TimestampUtils::setServerSendTimestamp(finalTimestamps); // Set serverSendMs to current time
    TimestampUtils::addTimestampsToHeader(response, finalTimestamps);

    response["body"] = message["body"];
    // Protocol: mirror header.message into body.errorCode on errors (see above).
    if (status == "error" && response["header"].contains("message") &&
        response["header"]["message"].is_string() &&
        (!response["body"].is_object() || !response["body"].contains("errorCode")))
    {
        if (!response["body"].is_object())
            response["body"] = nlohmann::json::object();
        response["body"]["errorCode"] = response["header"]["message"];
    }

    std::string responseString = response.dump();

    log_->debug("Response with timestamps generated: " + responseString);

    return responseString + "\n";
}
