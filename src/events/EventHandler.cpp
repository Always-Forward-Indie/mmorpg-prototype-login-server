#include "events/EventHandler.hpp"
#include "events/Event.hpp"

EventHandler::EventHandler(NetworkManager &networkManager,
                           Database &database,
                           CharacterManager &characterManager,
                           Logger &logger)
    : networkManager_(networkManager),
      database_(database),
      logger_(logger),
      characterManager_(characterManager)
{
}

void EventHandler::handleAuthentificateClientEvent(const Event &event, ClientData &clientData)
{
    // Here we will update the init data of the character when client joined in the object and send it to the client
    // Retrieve the data from the event
    const auto data = event.getData();
    int clientID = event.getClientID();

    Authenticator authenticator;

    // Extract init data
    try
    {
        // Try to extract the data
        if (std::holds_alternative<ClientDataStruct>(data))
        {
            ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);

            // Authenticate the client
            bool authStatus = authenticator.authenticate(database_, clientData, passedClientData.login, passedClientData.password);

            // Get the clientData object with the new init data
            const ClientDataStruct *currentClientData = clientData.getClientData(clientID);
            std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket = currentClientData->socket;

            // Prepare the response message
            nlohmann::json response;
            ResponseBuilder builder;

            // Check if the authentication is not successful
            if (currentClientData->clientId == 0 || currentClientData->hash == "" || !authStatus)
            {
                // Add response data
                response = builder
                               .setHeader("message", "Authentication failed for user!")
                               .setHeader("hash", passedClientData.hash)
                               .setHeader("login", passedClientData.login)
                               .setHeader("clientId", passedClientData.clientId)
                               .setHeader("eventType", "authentificationClient")
                               .setBody("", "")
                               .build();
                // Prepare a response message
                std::string responseData = networkManager_.generateResponseMessage("error", response);
                // Send the response to the client
                networkManager_.sendResponse(clientSocket, responseData);
                return;
            }

            // Add the message to the response
            response = builder
                           .setHeader("message", "Authentication success for user!")
                           .setHeader("hash", currentClientData->hash)
                           .setHeader("login", currentClientData->login)
                           .setHeader("clientId", currentClientData->clientId)
                           .setHeader("eventType", "authentificationClient")
                           .setBody("", "")
                           .build();
            // Prepare a response message
            std::string responseData = networkManager_.generateResponseMessage("success", response);

            // Send data to the client
            networkManager_.sendResponse(clientSocket, responseData);
        }
        else
        {
            logger_.log("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here: " + std::string(ex.what()));
    }
}


//TODO rework this method
void EventHandler::handleGetCharactersListEvent(const Event &event, ClientData &clientData)
{
    // Here we will get the characters list from the database and send it to the client
    // Retrieve the data from the event
    const auto data = event.getData();
    int clientID = event.getClientID();

    // Extract init data
    try
    {
        // Try to extract the data
        if (std::holds_alternative<ClientDataStruct>(data))
        {
            ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);
            // Save the clientData object with the new init data
            clientData.storeClientData(passedClientData);

            // Get the clientData object with the new init data
            const ClientDataStruct *currentClientData = clientData.getClientData(passedClientData.clientId);

            // Prepare the response message
            nlohmann::json response;
            ResponseBuilder builder;

            // Check if the authentication is not successful
            if (passedClientData.clientId == 0 || passedClientData.hash == "")
            {
                // Add response data
                response = builder
                               .setHeader("message", "Authentication failed for user!")
                               .setHeader("hash", passedClientData.hash)
                               .setHeader("clientId", passedClientData.clientId)
                               .setHeader("eventType", "getCharactersList")
                               .setBody("", "")
                               .build();
                // Prepare a response message
                std::string responseData = networkManager_.generateResponseMessage("error", response);
                // Send the response to the client
                networkManager_.sendResponse(passedClientData.socket, responseData);
                return;
            }

            // Get the character list from the database
            std::vector<CharacterDataStruct> charactersList = characterManager_.getCharactersList(database_, clientData, clientID);

            // convert the charactersList to a json object
            nlohmann::json charactersListJson = nlohmann::json::array();
            for (const auto &character : charactersList)
            {
                nlohmann::json characterJson;
                characterJson["characterId"] = character.characterId;
                characterJson["characterName"] = character.characterName;
                characterJson["characterClass"] = character.characterClass;
                characterJson["characterLevel"] = character.characterLevel;
                charactersListJson.push_back(characterJson);
            }

            // Add the message to the response
            response = builder
                           .setHeader("message", "Characters list retrieved successfully!")
                           .setHeader("hash", currentClientData->hash)
                           .setHeader("clientId", currentClientData->clientId)
                           .setHeader("eventType", "getCharactersList")
                           .setBody("charactersList", charactersListJson)
                           .build();
            // Prepare a response message
            std::string responseData = networkManager_.generateResponseMessage("success", response);

            // Send data to the the client
            networkManager_.sendResponse(passedClientData.socket, responseData);
        }
        else
        {
            logger_.log("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here: " + std::string(ex.what()));
    }
}


void EventHandler::dispatchEvent(const Event &event, ClientData &clientData)
{
    switch (event.getType())
    {
    case Event::AUTH_CLIENT:
        handleAuthentificateClientEvent(event, clientData);
        break;
    case Event::GET_CHARACTERS_LIST:
        handleGetCharactersListEvent(event, clientData);
        break;
        // Other cases...
    }
}