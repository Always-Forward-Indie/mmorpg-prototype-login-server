#include "login_server/LoginServer.hpp"
#include <iostream>

//TODO - Global refactor server code according to the new architecture (implemented already in game server, chunk server)
LoginServer::LoginServer(boost::asio::io_context& io_context, const std::string& customIP, short customPort, short maxClients)
    : io_context_(io_context),
      acceptor_(io_context),
      clientData_(),
      authenticator_(),
      characterManager_(),
      database_() {
    boost::system::error_code ec;
    
    // Create an endpoint with the custom IP and port
    boost::asio::ip::tcp::endpoint endpoint(boost::asio::ip::address::from_string(customIP), customPort);

    acceptor_.open(endpoint.protocol(), ec);
    if (!ec) {
        acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true), ec);
        acceptor_.bind(endpoint, ec);
        acceptor_.listen(maxClients, ec);
    }

    if (ec) {
        std::cerr << "Error during server initialization: " << ec.message() << std::endl;
        return;
    }

    startAccept();

    // Print IP address and port when the server starts
    std::cout << "Login Server started on IP: " << customIP << ", Port: " << customPort << std::endl;
}

void LoginServer::startAccept() {
    std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket = std::make_shared<boost::asio::ip::tcp::socket>(io_context_);
    acceptor_.async_accept(*clientSocket, [this, clientSocket](const boost::system::error_code& error) {
        if (!error) {
            // Get the client's remote endpoint (IP address and port)
            boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint();
            std::string clientIP = remoteEndpoint.address().to_string();

            // Print the client's IP address
            std::cout << "New client with IP: " << clientIP << " connected!" << std::endl;

            // Start reading data from the client
            startReadingFromClient(clientSocket);
        }

        // Continue accepting new connections even if there's an error
        startAccept();
    });
}

void LoginServer::handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::array<char, max_length>& dataBuffer, size_t bytes_transferred) {
    try {
        nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
        // Initialize the client ID to 0
        int clientID = 0;
        // Initialize the character ID to 0
        int characterID = 0;
        // Create a JSON object for the response
        nlohmann::json response;
        // Extract hash, login fields from the jsonData
        std::string type = jsonData["eventType"]!=nullptr ? jsonData["eventType"] : "";
        std::string hash = jsonData["hash"]!=nullptr ? jsonData["hash"] : "";

        std::cout << "Type: " << type << std::endl;

        // Check if the type of request is authentification
        if(type == "authentification") {
            std::string login = jsonData["login"];
            std::string password = jsonData["password"];
            authenticateClient(clientSocket, login, password);
        }

        // Check if the type of request is character_list
        if(type == "getCharactersList") {
            std::cout << "Get characters list" << std::endl;

            // Get the client ID from the jsonData
            if(jsonData["clientId"].is_number_integer()) {
                clientID = jsonData["clientId"];
            } else {
                clientID = std::stoi(jsonData["clientId"].get<std::string>());
            }
            
            getCharactersList(clientSocket, clientID, hash);
        }

        // Check if the type of request is character_list
        if(type == "selectCharacter") {
            // Get the client ID from the jsonData
            if(jsonData["clientId"].is_number_integer()) {
                clientID = jsonData["clientId"];
            } else {
                clientID = std::stoi(jsonData["clientId"].get<std::string>());
            }

            // Get the character ID from the jsonData
            if(jsonData["characterId"].is_number_integer()) {
                characterID = jsonData["characterId"];
            } else {
                characterID = std::stoi(jsonData["characterId"].get<std::string>());
            }
            
            selectCharacter(clientSocket, clientID, characterID, hash);
        }

        
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "JSON parsing error: " << e.what() << std::endl;
        // Handle the error (e.g., close the socket)
    }
}

void LoginServer::authenticateClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string& login, const std::string& password) {
        // Authenticate the client
        int clientID = authenticator_.authenticate(database_, clientData_, login, password);
        // Get the client ID from the clientData_ object
        const ClientDataStruct* currentClientData = clientData_.getClientData(clientID);
        // Create a JSON object for the response
        nlohmann::json response;

        if (clientID != 0) {
            // Add the message to the response
            response["message"] = "Authentication success for user!";
            response["hash"] = currentClientData->hash;
            response["login"] = currentClientData->login;
            response["clientId"] = currentClientData->clientId;
            // Prepare a response message
            std::string responseData = generateResponseMessage("success", response, clientID);
            // Send the response to the client
            sendResponse(clientSocket, responseData);
        } else {
            // Add the message to the response
            response["message"] = "Authentication failed for user!";
            // Prepare a response message
            std::string responseData = generateResponseMessage("error", response, 0);
            // Send the response to the client
            sendResponse(clientSocket, responseData);
        }
}

void LoginServer::getCharactersList(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int& clientID, const std::string& hash) {
    // Create a JSON object for the response
    nlohmann::json response;
    
    // Get the client ID from the clientData_ object
    const ClientDataStruct* currentClientData = clientData_.getClientData(clientID);
    // Get the characters list from the characterManager_
    std::vector<CharacterDataStruct> characters = characterManager_.getCharactersList(database_, clientData_, currentClientData->clientId);
    //std::cerr << "Client ID: " << currentClientData->clientId << std::endl;
    //std::cerr << "Client Character Name: " << characters.size() << std::endl;

    if (currentClientData && !characters.empty()) {
        
        // Create an nlohmann::json array and populate it with the vector elements
        nlohmann::json characterArray;
        for (const auto& character : characters) {
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
    } else {
        // Add the message to the response
        response["message"] = "Characters list retrieved failder!";
        // Prepare a response message
        std::string responseData = generateResponseMessage("error", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
}

void LoginServer::selectCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int& clientID, const int& characterID, const std::string& hash) {
    // Create a JSON object for the response
    nlohmann::json response;

    // Get the character
    CharacterDataStruct character = characterManager_.selectCharacter(database_, clientData_, clientID, characterID);
    
    // Get the client ID from the clientData_ object
    const ClientDataStruct* currentClientData = clientData_.getClientData(clientID);
    
    if (currentClientData && character.characterId != 0) {
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
    } else {
        // Add the message to the response
        response["message"] = "Character data retrieved failder!";
        // Prepare a response message
        std::string responseData = generateResponseMessage("error", response, clientID);
        // Send the response to the client
        sendResponse(clientSocket, responseData);
    }
}

void LoginServer::sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string& responseString) {
    boost::asio::async_write(*clientSocket, boost::asio::buffer(responseString),
                             [this, clientSocket](const boost::system::error_code& error, size_t bytes_transferred) {
                                 if (!error) {
                                     // Response sent successfully, now start listening for the client's next message
                                     startReadingFromClient(clientSocket);
                                 } else {
                                     std::cerr << "Error during async_write: " << error.message() << std::endl;
                                     // Handle the error (e.g., close the socket)
                                 }
                             });
}

void LoginServer::startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket) {
    auto dataBuffer = std::make_shared<std::array<char, max_length>>();
    clientSocket->async_read_some(boost::asio::buffer(*dataBuffer),
        [this, clientSocket, dataBuffer](const boost::system::error_code& error, size_t bytes_transferred) {
            if (!error) {
                // Data has been read successfully, handle it
                handleClientData(clientSocket, *dataBuffer, bytes_transferred);

                // Continue reading from the client
                startReadingFromClient(clientSocket);
            } else if (error == boost::asio::error::eof) {
                // The client has closed the connection
                std::cerr << "Client disconnected gracefully." << std::endl;

                // You can perform any cleanup or logging here if needed

                // Close the client socket
                clientSocket->close();
            } else if (error == boost::asio::error::operation_aborted) {
                // The read operation was canceled, likely due to the client disconnecting
                std::cerr << "Read operation canceled (client disconnected)." << std::endl;

                // You can perform any cleanup or logging here if needed

                // Close the client socket
                clientSocket->close();
            } else {
                // Handle other errors
                std::cerr << "Error during async_read_some: " << error.message() << std::endl;

                // You can also close the socket in case of other errors if needed
                clientSocket->close();
            }
        });
}

std::string LoginServer::generateResponseMessage(const std::string& status, const nlohmann::json& message, const int& id) {
    nlohmann::json response;

    response["status"] = status;
    response["body"] = message;

    std::string responseString = response.dump();

    std::cerr << "Client data: " << responseString << std::endl;

    return responseString;
}