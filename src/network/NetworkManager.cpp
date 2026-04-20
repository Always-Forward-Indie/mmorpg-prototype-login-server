#include "network/NetworkManager.hpp"
#include "utils/TimestampUtils.hpp"
#include <spdlog/logger.h>

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
    short customPort = std::get<1>(configs).port;
    std::string customIP = std::get<1>(configs).host;
    short maxClients = std::get<1>(configs).max_clients;

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

        // Log the received message
        log_->info("Received data from Client: " + message);

        // Process the message
        processMessage(clientSocket, message);

        // Erase processed message and delimiter from the buffer
        accumulatedData.erase(0, delimiterPos + 1); // +1 to remove the delimiter as well
    }

    // Store any remaining partial message back into the per-socket buffer
    if (!accumulatedData.empty())
    {
        std::lock_guard<std::mutex> lock(socketBufferMutex_);
        socketBuffers_[clientSocket.get()] = std::move(accumulatedData);
    }
}

void NetworkManager::processMessage(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &message)
{
    // Convert the message string to a buffer array for parsing
    std::array<char, max_length> messageBuffer;
    std::copy(message.begin(), message.end(), messageBuffer.begin());
    size_t messageLength = message.length();

    // Now we can use JSON parsing logic on the `messageBuffer` with `messageLength` bytes of data
    try
    {
        // Parse the data received from the client using JSONParser
        std::string eventType = jsonParser_.parseEventType(messageBuffer, messageLength);
        ClientDataStruct clientData = jsonParser_.parseClientData(messageBuffer, messageLength);
        CharacterDataStruct characterData = jsonParser_.parseCharacterData(messageBuffer, messageLength);
        PositionStruct positionData = jsonParser_.parsePositionData(messageBuffer, messageLength);
        MessageStruct messageStruct = jsonParser_.parseMessage(messageBuffer, messageLength);

        // Parse timestamps for lag compensation
        TimestampStruct timestamps = TimestampUtils::parseTimestampsFromBuffer(messageBuffer, messageLength);

        log_->info("Event type: " + eventType);
        log_->info("Client ID: " + std::to_string(clientData.clientId));
        log_->info("Client hash: " + clientData.hash);
        log_->info("Character ID: " + std::to_string(characterData.characterId));

        // Check if the type of request is authentificationClient
        if (eventType == "authentificationClient" && clientData.login != "" && clientData.password != "")
        {
            // Set the client data
            // characterData.characterPosition = positionData;
            // clientData.characterData = characterData;
            clientData.socket = clientSocket;

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

            // Parse login/password/email from body (re-use already-parsed JSON)
            try
            {
                nlohmann::json parsed = nlohmann::json::parse(
                    std::string(messageBuffer.data(), messageBuffer.data() + messageLength));
                if (parsed.contains("body") && parsed["body"].is_object())
                {
                    const auto &body = parsed["body"];
                    if (body.contains("login") && body["login"].is_string())
                        reg.login = body["login"].get<std::string>();
                    if (body.contains("password") && body["password"].is_string())
                        reg.password = body["password"].get<std::string>();
                    if (body.contains("email") && body["email"].is_string())
                        reg.email = body["email"].get<std::string>();
                }
            }
            catch (...)
            {
            }

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
    catch (const nlohmann::json::parse_error &e)
    {
        logger_.logError("JSON parsing error: " + std::string(e.what()), RED);
    }
}

void NetworkManager::sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &responseString)
{
    // CRITICAL-11 fix: responseString is a const-ref parameter; it may be destroyed before
    // async_write completes. Copy once into a shared_ptr to keep data alive until completion.
    auto dataPtr = std::make_shared<const std::string>(responseString);

    boost::asio::async_write(*clientSocket, boost::asio::buffer(*dataPtr),
                             [this, clientSocket, dataPtr](const boost::system::error_code &error, size_t bytes_transferred)
                             {
                                 boost::system::error_code ec;
                                 boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(ec);
                                 if (!ec)
                                 {
                                     // Successfully retrieved the remote endpoint
                                     std::string ipAddress = remoteEndpoint.address().to_string();
                                     std::string portNumber = std::to_string(remoteEndpoint.port());

                                     log_->debug("Bytes send: " + std::to_string(bytes_transferred));
                                     log_->debug("Data send successfully to the Client: " + ipAddress + ", Port: " + portNumber);

                                     // Now you can use ipAddress and portNumber as needed
                                 }
                                 else
                                 {
                                     // Handle error
                                 }

                                 if (!error)
                                 {
                                     // Response sent successfully, now start listening for the client's next message
                                     startReadingFromClient(clientSocket);
                                 }
                                 else
                                 {
                                     log_->error("Error during async_write: " + error.message());
                                 }
                             });
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

                                          log_->info("Bytes received: " + std::to_string(bytes_transferred));
                                          log_->info("Data received from Client IP address: " + ipAddress + ", Port: " + portNumber);
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
                                          // NOTE: do NOT call startReadingFromClient here.
                                          // sendResponse's completion handler continues the read loop
                                          // after the response is written, preventing two concurrent reads.
                                      }
                                      else if (error == boost::asio::error::eof)
                                      {
                                          // The client has closed the connection
                                          log_->error("Client disconnected gracefully.");

                                          {
                                              std::lock_guard<std::mutex> lock(socketBufferMutex_);
                                              socketBuffers_.erase(clientSocket.get());
                                          }
                                          boost::system::error_code closeEc;
                                          clientSocket->close(closeEc);
                                      }
                                      else if (error == boost::asio::error::operation_aborted)
                                      {
                                          // The read operation was canceled, likely due to the client disconnecting
                                          log_->error("Read operation canceled (client disconnected).");

                                          {
                                              std::lock_guard<std::mutex> lock(socketBufferMutex_);
                                              socketBuffers_.erase(clientSocket.get());
                                          }
                                          boost::system::error_code closeEc;
                                          clientSocket->close(closeEc);
                                      }
                                      else
                                      {
                                          // Handle other errors
                                          log_->error("Error during async_read_some: " + error.message());

                                          {
                                              std::lock_guard<std::mutex> lock(socketBufferMutex_);
                                              socketBuffers_.erase(clientSocket.get());
                                          }
                                          boost::system::error_code closeEc;
                                          clientSocket->close(closeEc);
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
    response["header"]["version"] = "1.0";
    response["body"] = message["body"];

    std::string responseString = response.dump();

    log_->info("Response generated: " + responseString);

    return responseString + "\n";
}

std::string NetworkManager::generateResponseMessage(const std::string &status, const nlohmann::json &message, const TimestampStruct &timestamps)
{
    nlohmann::json response;
    std::string currentTimestamp = TimestampUtils::getCurrentTimestamp();
    response["header"] = message["header"];
    response["header"]["status"] = status;
    response["header"]["timestamp"] = currentTimestamp;
    response["header"]["version"] = "1.0";

    // Add lag compensation timestamps to header
    TimestampStruct finalTimestamps = timestamps;
    TimestampUtils::setServerSendTimestamp(finalTimestamps); // Set serverSendMs to current time
    TimestampUtils::addTimestampsToHeader(response, finalTimestamps);

    response["body"] = message["body"];

    std::string responseString = response.dump();

    log_->info("Response with timestamps generated: " + responseString);

    return responseString + "\n";
}
