#include "login_server/LoginServer.hpp"
#include <iostream>

// TODO - Implement events functionality to the server and move the logic to the events
LoginServer::LoginServer(ClientData &clientData, CharacterManager &characterManager, Database &database, std::tuple<DatabaseConfig, LoginServerConfig> &configs, Logger &logger)
    : acceptor_(io_context_),
      clientData_(clientData),
      characterManager_(characterManager),
      database_(database),
      configs_(configs),
      logger_(logger)
{
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
        logger_.log("Starting Login Server...", YELLOW);
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
    logger_.log("Login Server started on IP: " + customIP + ", Port: " + std::to_string(customPort), GREEN);
}

void LoginServer::startAccept()
{
    std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket = std::make_shared<boost::asio::ip::tcp::socket>(io_context_);

    acceptor_.async_accept(*clientSocket, [this, clientSocket](const boost::system::error_code &error)
                           {
                if (!error) {
                    // Get the Client remote endpoint (IP address and port)
                    boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint();
                    std::string clientIP = remoteEndpoint.address().to_string();
                    std::string portNumber = std::to_string(remoteEndpoint.port());

                    // Print the Client IP address
                    logger_.log("New Client with IP: " + clientIP + " Port: " + portNumber + " - connected!", GREEN);
                    
                    // Start reading data from the client
                    startReadingFromClient(clientSocket);
                }

                // Continue accepting new connections even if there's an error
                startAccept(); });
}

void LoginServer::startIOEventLoop()
{
    logger_.log("Starting Login Server IO Context...", YELLOW);
    io_context_.run(); // Start the event loop
}

    void LoginServer::handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket,
                                        const std::array<char, max_length> &dataBuffer,
                                        size_t bytes_transferred) {
        static std::string accumulatedData; // Buffer to accumulate data

        // Append new data to the accumulated buffer
        accumulatedData.append(dataBuffer.data(), bytes_transferred);

        // Check for the delimiter in the accumulated data
        std::string delimiter = "\r\n\r\n"; // Your chosen delimiter
        size_t delimiterPos;
        while ((delimiterPos = accumulatedData.find(delimiter)) != std::string::npos) { // Assuming '\r\n\r\n' is the delimiter
            // Extract one message up to the delimiter
            std::string message = accumulatedData.substr(0, delimiterPos);

            // Log the received message
            logger_.log("Received data from Client: " + message, YELLOW);

            // Process the message
            processMessage(clientSocket, message);

            // Erase processed message and delimiter from the buffer
            accumulatedData.erase(0, delimiterPos + 1); // +1 to remove the delimiter as well
        }
    }

    void LoginServer::processMessage(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string& message) {
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
            MessageStruct message = jsonParser_.parseMessage(messageBuffer, messageLength);

            logger_.log("Event type: " + eventType, YELLOW);
            logger_.log("Client ID: " + std::to_string(clientData.clientId), YELLOW);
            logger_.log("Client hash: " + clientData.hash, YELLOW);
            logger_.log("Character ID: " + std::to_string(characterData.characterId), YELLOW);

            // Check if the type of request is authentification
            if (eventType == "authentification" && clientData.hash != "" && clientData.clientId != 0)
            {
                // Set the client data
                characterData.characterPosition = positionData;
                clientData.characterData = characterData;
                clientData.socket = clientSocket;

                // Create a new event where join to Chunk Server and push it to the queue
                Event joinToChunkEvent(Event::JOIN_CHARACTER_CHUNK, clientData.clientId, clientData, clientSocket);
                eventQueue_.push(joinToChunkEvent);
            }
        }
        catch (const nlohmann::json::parse_error &e)
        {
            logger_.logError("JSON parsing error: " + std::string(e.what()), RED);
        }
    }

void LoginServer::handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    try
    {
        nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
        // Initialize the client ID to 0
        int clientID = 0;
        // Initialize the character ID to 0
        int characterID = 0;
        // Create a JSON object for the response
        nlohmann::json response;
        // Extract hash, login fields from the jsonData
        std::string type = jsonData["eventType"] != nullptr ? jsonData["eventType"] : "";
        std::string hash = jsonData["hash"] != nullptr ? jsonData["hash"] : "";

        std::cout << "Type: " << type << std::endl;

        // Check if the type of request is authentification
        if (type == "authentification")
        {
            std::string login = jsonData["login"];
            std::string password = jsonData["password"];
            authenticateClient(clientSocket, login, password);
        }

        // Check if the type of request is character_list
        if (type == "getCharactersList")
        {
            std::cout << "Get characters list" << std::endl;

            // Get the client ID from the jsonData
            if (jsonData["clientId"].is_number_integer())
            {
                clientID = jsonData["clientId"];
            }
            else
            {
                clientID = std::stoi(jsonData["clientId"].get<std::string>());
            }

            getCharactersList(clientSocket, clientID, hash);
        }

        // Check if the type of request is character_list
        if (type == "selectCharacter")
        {
            // Get the client ID from the jsonData
            if (jsonData["clientId"].is_number_integer())
            {
                clientID = jsonData["clientId"];
            }
            else
            {
                clientID = std::stoi(jsonData["clientId"].get<std::string>());
            }

            // Get the character ID from the jsonData
            if (jsonData["characterId"].is_number_integer())
            {
                characterID = jsonData["characterId"];
            }
            else
            {
                characterID = std::stoi(jsonData["characterId"].get<std::string>());
            }

            selectCharacter(clientSocket, clientID, characterID, hash);
        }
    }
    catch (const nlohmann::json::parse_error &e)
    {
        std::cerr << "JSON parsing error: " << e.what() << std::endl;
        // Handle the error (e.g., close the socket)
    }
}

void LoginServer::authenticateClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &login, const std::string &password)
{
    // Authenticate the client
    int clientID = authenticator_.authenticate(database_, clientData_, login, password);
    // Get the client ID from the clientData_ object
    const ClientDataStruct *currentClientData = clientData_.getClientData(clientID);
    // Create a JSON object for the response
    nlohmann::json response;

    if (clientID != 0)
    {
        // Add the message to the response
        response["message"] = "Authentication success for user!";
        response["hash"] = currentClientData->hash;
        response["login"] = currentClientData->login;
        response["clientId"] = currentClientData->clientId;
        // Prepare a response message
        std::string responseData = generateResponseMessage("success", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
    else
    {
        // Add the message to the response
        response["message"] = "Authentication failed for user!";
        // Prepare a response message
        std::string responseData = generateResponseMessage("error", response, 0);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
}

void LoginServer::getCharactersList(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const std::string &hash)
{
    // Create a JSON object for the response
    nlohmann::json response;

    // Get the client ID from the clientData_ object
    const ClientDataStruct *currentClientData = clientData_.getClientData(clientID);
    // Get the characters list from the characterManager_
    std::vector<CharacterDataStruct> characters = characterManager_.getCharactersList(database_, clientData_, currentClientData->clientId);
    // std::cerr << "Client ID: " << currentClientData->clientId << std::endl;
    // std::cerr << "Client Character Name: " << characters.size() << std::endl;

    if (currentClientData && !characters.empty())
    {

        // Create an nlohmann::json array and populate it with the vector elements
        nlohmann::json characterArray;
        for (const auto &character : characters)
        {
            nlohmann::json characterJson;
            characterJson["characterId"] = character.characterId;
            characterJson["characterLevel"] = character.characterLevel;
            characterJson["characterName"] = character.characterName;
            characterJson["characterClass"] = character.characterClass;
            characterArray.push_back(characterJson);
        }

        // Add the characters list and message to the response
        response["message"] = "Characters list retrieved successfully!";
        response["hash"] = currentClientData->hash;
        response["login"] = currentClientData->login;
        response["clientId"] = currentClientData->clientId;
        response["characters"] = characterArray.dump();
        // Prepare a response message
        std::string responseData = generateResponseMessage("success", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
    else
    {
        // Add the message to the response
        response["message"] = "Characters list retrieved failder!";
        // Prepare a response message
        std::string responseData = generateResponseMessage("error", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
}

void LoginServer::selectCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const int &characterID, const std::string &hash)
{
    // Create a JSON object for the response
    nlohmann::json response;

    // Get the character
    CharacterDataStruct character = characterManager_.selectCharacter(database_, clientData_, clientID, characterID);

    // Get the client ID from the clientData_ object
    const ClientDataStruct *currentClientData = clientData_.getClientData(clientID);

    if (currentClientData && character.characterId != 0)
    {
        // Add the character data and message to the response
        response["message"] = "Characters list retrieved successfully!";
        response["hash"] = currentClientData->hash;
        response["login"] = currentClientData->login;
        response["clientId"] = currentClientData->clientId;
        response["character_name"] = currentClientData->characterData.characterName;
        response["character_class"] = currentClientData->characterData.characterClass;
        response["character_id"] = currentClientData->characterData.characterId;
        response["character_level"] = currentClientData->characterData.characterLevel;
        // Prepare a response message
        std::string responseData = generateResponseMessage("success", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
    else
    {
        // Add the message to the response
        response["message"] = "Character data retrieved failder!";
        // Prepare a response message
        std::string responseData = generateResponseMessage("error", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
}

void LoginServer::sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &responseString)
{
        boost::asio::async_write(*clientSocket, boost::asio::buffer(responseString),
                                [this, clientSocket](const boost::system::error_code &error, size_t bytes_transferred)
                                {
                                        boost::system::error_code ec;
                                        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(ec);
                                            if (!ec) {
                                                // Successfully retrieved the remote endpoint
                                                std::string ipAddress = remoteEndpoint.address().to_string();
                                                std::string portNumber = std::to_string(remoteEndpoint.port());

                                                logger_.log("Bytes send: " + std::to_string(bytes_transferred), BLUE);
                                                logger_.log("Data send successfully to the Client: " + ipAddress + ", Port: " + portNumber, BLUE);
                                               
                                                // Now you can use ipAddress and portNumber as needed
                                            } else {
                                                // Handle error
                                            }

                                    if (!error)
                                    {
                                        // Response sent successfully, now start listening for the client's next message
                                        startReadingFromClient(clientSocket);
                                    }
                                    else
                                    {
                                        logger_.logError("Error during async_write: " + error.message(), RED);
                                    }
                                });
}

void LoginServer::startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket)
{
    auto dataBufferClient = std::make_shared<std::array<char, max_length>>();
        std::fill(dataBufferClient->begin(), dataBufferClient->end(), 0); // Clear the buffer


        clientSocket->async_read_some(boost::asio::buffer(*dataBufferClient),
                                    [this, clientSocket, dataBufferClient](const boost::system::error_code &error, size_t bytes_transferred)
                                    {
                                        boost::system::error_code ec;
                                        boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint(ec);
                                            if (!ec) {
                                                // Successfully retrieved the remote endpoint
                                                std::string ipAddress = remoteEndpoint.address().to_string();
                                                std::string portNumber = std::to_string(remoteEndpoint.port());

                                                logger_.log("Bytes received: " + std::to_string(bytes_transferred), YELLOW);
                                                logger_.log("Data received from Client IP address: " + ipAddress + ", Port: " + portNumber, YELLOW);
                                            } else {
                                                // Handle error
                                            }

                                           
                                            // start reading from the client
                                        if (!error)
                                        {
                                            // Data has been read successfully, handle it
                                            handleClientData(clientSocket, *dataBufferClient, bytes_transferred);

                                            // Continue reading from the client
                                            startReadingFromClient(clientSocket);
                                        }
                                        else if (error == boost::asio::error::eof)
                                        {

                                            // The client has closed the connection
                                            logger_.logError("Client disconnected gracefully.");

                                            // You can perform any cleanup or logging here if needed

                                            // Close the client socket
                                            clientSocket->close();
                                        }
                                        else if (error == boost::asio::error::operation_aborted)
                                        {
                                            // The read operation was canceled, likely due to the client disconnecting
                                            logger_.logError("Read operation canceled (client disconnected).");

                                            // You can perform any cleanup or logging here if needed

                                            // Close the client socket
                                            clientSocket->close();
                                        }
                                        else
                                        {
                                            // Handle other errors
                                            logger_.logError("Error during async_read_some: " + error.message());

                                            // You can also close the socket in case of other errors if needed
                                            clientSocket->close();
                                        }
                                    });
}

std::string LoginServer::generateResponseMessage(const std::string &status, const nlohmann::json &message, const int &id)
{
        nlohmann::json response;
        std::string currentTimestamp = logger_.getCurrentTimestamp();
        response["header"] = message["header"];
        response["header"]["status"] = status;
        response["header"]["timestamp"] = currentTimestamp;
        response["header"]["version"] = "1.0";
        response["body"] = message["body"];

        std::string responseString = response.dump();

        logger_.log("Response generated: " + responseString, YELLOW);

        return responseString+ "\n";
}