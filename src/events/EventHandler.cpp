#include "events/EventHandler.hpp"
#include "events/Event.hpp"
#include <spdlog/logger.h>

EventHandler::EventHandler(NetworkManager &networkManager,
                           DatabasePool &pool,
                           CharacterManager &characterManager,
                           Logger &logger)
    : networkManager_(networkManager),
      pool_(pool),
      logger_(logger),
      characterManager_(characterManager),
      accountManager_(logger)
{
    log_ = logger.getSystem("events");
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
            auto poolGuard = pool_.acquire();
            int authClientID = authenticator.authenticate(poolGuard.get(), clientData, passedClientData.login, passedClientData.password);

            // Get the clientData object with the new init data
            const ClientDataStruct *currentClientData = clientData.getClientData(authClientID);
            std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket = passedClientData.socket;

            // Prepare the response message
            nlohmann::json response;
            ResponseBuilder builder;

            // Check if the authentication is not successful
            if (authClientID == 0)
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
            log_->info("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here: " + std::string(ex.what()));
    }
}

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
            auto poolGuard = pool_.acquire();
            std::vector<CharacterDataStruct> charactersList = characterManager_.getCharactersList(poolGuard.get(), clientData, clientID);

            // convert the charactersList to a json object
            nlohmann::json charactersListJson = nlohmann::json::array();
            for (const auto &character : charactersList)
            {
                nlohmann::json characterJson;
                characterJson["characterId"] = character.characterId;
                characterJson["characterName"] = character.characterName;
                characterJson["classSlug"] = character.characterClass;
                characterJson["raceSlug"] = character.characterRace;
                characterJson["genderSlug"] = character.characterGender;
                characterJson["characterLevel"] = character.characterLevel;

                // Fetch equipment preview for this character (for character-selection screen)
                std::vector<EquipmentPreviewItemStruct> equip =
                    characterManager_.getCharacterEquipmentPreview(poolGuard.get(), character.characterId);
                nlohmann::json equipJson = nlohmann::json::array();
                for (const auto &item : equip)
                {
                    nlohmann::json itemJson;
                    itemJson["slotId"] = item.slotId;
                    itemJson["itemSlug"] = item.itemSlug;
                    equipJson.push_back(itemJson);
                }
                characterJson["equipment"] = equipJson;

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
            log_->info("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here: " + std::string(ex.what()));
    }
}

void EventHandler::handleCreateCharacterEvent(const Event &event, ClientData &clientData)
{
    const auto data = event.getData();

    try
    {
        if (std::holds_alternative<ClientDataStruct>(data))
        {
            ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);

            nlohmann::json response;
            ResponseBuilder builder;

            // Auth guard
            if (passedClientData.clientId == 0 || passedClientData.hash.empty())
            {
                response = builder
                               .setHeader("message", "Unauthorized")
                               .setHeader("hash", passedClientData.hash)
                               .setHeader("clientId", passedClientData.clientId)
                               .setHeader("eventType", "createCharacter")
                               .setBody("", "")
                               .build();
                networkManager_.sendResponse(passedClientData.socket,
                                             networkManager_.generateResponseMessage("error", response));
                return;
            }

            const CharacterDataStruct &charData = passedClientData.characterData;

            auto poolGuard = pool_.acquire();
            int result = characterManager_.createCharacter(
                poolGuard.get(),
                passedClientData.clientId,
                charData.characterName,
                charData.characterClass,
                charData.characterRace,
                charData.characterGender);

            if (result <= 0)
            {
                std::string errorMsg;
                switch (static_cast<CharacterCreateResult>(result))
                {
                case CharacterCreateResult::ERR_NAME_TAKEN:
                    errorMsg = "ERR_CHAR_NAME_TAKEN";
                    break;
                case CharacterCreateResult::ERR_NAME_INVALID:
                    errorMsg = "ERR_CHAR_NAME_INVALID";
                    break;
                case CharacterCreateResult::ERR_SLOT_FULL:
                    errorMsg = "ERR_CHAR_SLOT_FULL";
                    break;
                case CharacterCreateResult::ERR_MISSING_FIELD:
                    errorMsg = "ERR_CHAR_MISSING_FIELD";
                    break;
                default:
                    errorMsg = "ERR_CHAR_CREATE_FAILED";
                    break;
                }
                response = builder
                               .setHeader("message", errorMsg)
                               .setHeader("hash", passedClientData.hash)
                               .setHeader("clientId", passedClientData.clientId)
                               .setHeader("eventType", "createCharacter")
                               .setBody("", "")
                               .build();
                networkManager_.sendResponse(passedClientData.socket,
                                             networkManager_.generateResponseMessage("error", response));
                return;
            }

            response = builder
                           .setHeader("message", "Character created successfully")
                           .setHeader("hash", passedClientData.hash)
                           .setHeader("clientId", passedClientData.clientId)
                           .setHeader("eventType", "createCharacter")
                           .setBody("characterId", result)
                           .build();
            networkManager_.sendResponse(passedClientData.socket,
                                         networkManager_.generateResponseMessage("success", response));
        }
        else
        {
            log_->info("handleCreateCharacterEvent: unexpected event data type");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("handleCreateCharacterEvent error: " + std::string(ex.what()));
    }
}

// disconnect the client
void EventHandler::handleDisconnectClientEvent(const Event &event, ClientData &clientData)
{
    // Here we will disconnect the client
    const auto data = event.getData();

    // Extract init data
    try
    {
        // Try to extract the data
        if (std::holds_alternative<ClientDataStruct>(data))
        {
            ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);

            // Remove the client data
            clientData.removeClientData(passedClientData.clientId);

            // send the response to all clients
            nlohmann::json response;
            ResponseBuilder builder;
            response = builder
                           .setHeader("message", "Client disconnected!")
                           .setHeader("hash", "")
                           .setHeader("clientId", passedClientData.clientId)
                           .setHeader("eventType", "disconnectClient")
                           .setBody("", "")
                           .build();
            std::string responseData = networkManager_.generateResponseMessage("success", response);

            // Send the response to the all existing clients in the clientDataMap
            for (auto const &client : clientData.getClientsDataMap())
            {
                networkManager_.sendResponse(client.second.socket, responseData);
            }
        }
        else
        {
            log_->info("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here:" + std::string(ex.what()));
    }
}

// ping the client
void EventHandler::handlePingClientEvent(const Event &event, ClientData &clientData)
{
    // Here we will ping the client
    const auto data = event.getData();

    // Extract init data
    try
    {
        // Try to extract the data
        if (std::holds_alternative<ClientDataStruct>(data))
        {
            ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);

            // Get timestamps from event for lag compensation
            TimestampStruct timestamps;
            bool hasTimestamps = false;

            try
            {
                if (event.hasTimestamps())
                {
                    timestamps = event.getTimestamps();
                    hasTimestamps = true;
                }
            }
            catch (const std::exception &)
            {
                // Event doesn't have timestamps, log warning but continue
                log_->info("Ping event without timestamps for client " + std::to_string(passedClientData.clientId));
            }

            // send the response to all clients
            nlohmann::json response;
            ResponseBuilder builder;

            if (hasTimestamps)
            {
                response = builder
                               .setHeader("message", "Pong!")
                               .setHeader("eventType", "pingClient")
                               .setTimestamps(timestamps)
                               .setBody("", "")
                               .build();
                std::string responseData = networkManager_.generateResponseMessage("success", response, timestamps);
                networkManager_.sendResponse(passedClientData.socket, responseData);
            }
            else
            {
                response = builder
                               .setHeader("message", "Pong!")
                               .setHeader("eventType", "pingClient")
                               .setBody("", "")
                               .build();
                std::string responseData = networkManager_.generateResponseMessage("success", response);
                networkManager_.sendResponse(passedClientData.socket, responseData);
            }
        }
        else
        {
            log_->info("Error with extracting data!");
        }
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("Error here:" + std::string(ex.what()));
    }
}

// ---------------------------------------------------------------------------
// handleRegisterAccountEvent
// ---------------------------------------------------------------------------
void EventHandler::handleRegisterAccountEvent(const Event &event, ClientData &clientData)
{
    const auto data = event.getData();
    try
    {
        if (!std::holds_alternative<RegistrationDataStruct>(data))
        {
            log_->warn("handleRegisterAccountEvent: unexpected event data type");
            // Cannot send a response without a valid socket; nothing to do.
            return;
        }

        RegistrationDataStruct reg = std::get<RegistrationDataStruct>(data);
        nlohmann::json response;
        ResponseBuilder builder;

        int userId = 0;
        std::string sessionHash;

        auto poolGuard = pool_.acquire();
        AccountRegisterResult result = accountManager_.registerAccount(
            poolGuard.get(), clientData,
            reg.login, reg.password, reg.email, reg.registrationIp,
            userId, sessionHash);

        if (result != AccountRegisterResult::OK)
        {
            std::string errorMsg;
            switch (result)
            {
            case AccountRegisterResult::ERR_LOGIN_TAKEN:
                errorMsg = "ERR_LOGIN_TAKEN";
                break;
            case AccountRegisterResult::ERR_LOGIN_INVALID:
                errorMsg = "ERR_LOGIN_INVALID";
                break;
            case AccountRegisterResult::ERR_PASSWORD_SHORT:
                errorMsg = "ERR_PASSWORD_TOO_SHORT";
                break;
            case AccountRegisterResult::ERR_PASSWORD_LONG:
                errorMsg = "ERR_PASSWORD_TOO_LONG";
                break;
            case AccountRegisterResult::ERR_EMAIL_INVALID:
                errorMsg = "ERR_EMAIL_INVALID";
                break;
            default:
                errorMsg = "ERR_REGISTER_FAILED";
                break;
            }
            response = builder
                           .setHeader("message", errorMsg)
                           .setHeader("hash", "")
                           .setHeader("clientId", 0)
                           .setHeader("eventType", "registerAccount")
                           .setBody("", "")
                           .build();
            networkManager_.sendResponse(reg.socket,
                                         networkManager_.generateResponseMessage("error", response));
            return;
        }

        response = builder
                       .setHeader("message", "Registration successful")
                       .setHeader("hash", sessionHash)
                       .setHeader("clientId", userId)
                       .setHeader("login", reg.login)
                       .setHeader("eventType", "registerAccount")
                       .setBody("", "")
                       .build();
        networkManager_.sendResponse(reg.socket,
                                     networkManager_.generateResponseMessage("success", response));
    }
    catch (const std::exception &ex)
    {
        logger_.logError("handleRegisterAccountEvent error: " + std::string(ex.what()));
        // Best-effort: try to extract socket and send an error response so the client
        // doesn't hang waiting indefinitely.
        try
        {
            if (std::holds_alternative<RegistrationDataStruct>(data))
            {
                const auto &reg = std::get<RegistrationDataStruct>(data);
                if (reg.socket)
                {
                    nlohmann::json errResponse;
                    ResponseBuilder builder;
                    errResponse = builder
                                      .setHeader("message", "ERR_INTERNAL")
                                      .setHeader("hash", "")
                                      .setHeader("clientId", 0)
                                      .setHeader("eventType", "registerAccount")
                                      .setBody("", "")
                                      .build();
                    networkManager_.sendResponse(reg.socket,
                                                 networkManager_.generateResponseMessage("error", errResponse));
                }
            }
        }
        catch (...)
        {
        }
    }
}

// ---------------------------------------------------------------------------
// handleGetCharacterCreationOptionsEvent
// ---------------------------------------------------------------------------
void EventHandler::handleGetCharacterCreationOptionsEvent(const Event &event, ClientData &clientData)
{
    const auto data = event.getData();
    try
    {
        if (!std::holds_alternative<ClientDataStruct>(data))
        {
            log_->info("handleGetCharacterCreationOptionsEvent: unexpected event data type");
            return;
        }

        ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);
        nlohmann::json response;
        ResponseBuilder builder;

        // Auth guard
        if (passedClientData.clientId == 0 || passedClientData.hash.empty())
        {
            response = builder
                           .setHeader("message", "Unauthorized")
                           .setHeader("hash", "")
                           .setHeader("clientId", 0)
                           .setHeader("eventType", "getCharacterCreationOptions")
                           .setBody("", "")
                           .build();
            networkManager_.sendResponse(passedClientData.socket,
                                         networkManager_.generateResponseMessage("error", response));
            return;
        }

        auto poolGuard = pool_.acquire();
        pqxx::work txn(poolGuard.get());

        pqxx::result classRows = txn.exec_prepared("get_character_classes");
        pqxx::result raceRows = txn.exec_prepared("get_character_races");
        pqxx::result genderRows = txn.exec_prepared("get_character_genders");
        txn.commit();

        nlohmann::json classes = nlohmann::json::array();
        nlohmann::json races = nlohmann::json::array();
        nlohmann::json genders = nlohmann::json::array();

        for (const auto &row : classRows)
        {
            nlohmann::json entry;
            entry["id"] = row["id"].as<int>();
            entry["name"] = row["name"].as<std::string>();
            entry["slug"] = row["slug"].is_null() ? "" : row["slug"].as<std::string>();
            entry["description"] = row["description"].is_null() ? "" : row["description"].as<std::string>();
            classes.push_back(entry);
        }

        for (const auto &row : raceRows)
        {
            nlohmann::json entry;
            entry["id"] = row["id"].as<int>();
            entry["name"] = row["name"].as<std::string>();
            entry["slug"] = row["slug"].as<std::string>();
            races.push_back(entry);
        }

        for (const auto &row : genderRows)
        {
            nlohmann::json entry;
            entry["id"] = row["id"].as<int>();
            entry["slug"] = row["name"].as<std::string>(); // name IS the slug ("male"/"female")
            entry["label"] = row["label"].as<std::string>();
            genders.push_back(entry);
        }

        response = builder
                       .setHeader("message", "Options retrieved successfully")
                       .setHeader("hash", passedClientData.hash)
                       .setHeader("clientId", passedClientData.clientId)
                       .setHeader("eventType", "getCharacterCreationOptions")
                       .setBody("classes", classes)
                       .setBody("races", races)
                       .setBody("genders", genders)
                       .build();
        networkManager_.sendResponse(passedClientData.socket,
                                     networkManager_.generateResponseMessage("success", response));
    }
    catch (const std::exception &ex)
    {
        logger_.log("handleGetCharacterCreationOptionsEvent error: " + std::string(ex.what()));
    }
}

// ---------------------------------------------------------------------------
// handleDeleteCharacterEvent
// ---------------------------------------------------------------------------
void EventHandler::handleDeleteCharacterEvent(const Event &event, ClientData &clientData)
{
    const auto data = event.getData();
    try
    {
        if (!std::holds_alternative<ClientDataStruct>(data))
        {
            log_->info("handleDeleteCharacterEvent: unexpected event data type");
            return;
        }

        ClientDataStruct passedClientData = std::get<ClientDataStruct>(data);
        nlohmann::json response;
        ResponseBuilder builder;

        // Auth guard
        if (passedClientData.clientId == 0 || passedClientData.hash.empty())
        {
            response = builder
                           .setHeader("message", "Unauthorized")
                           .setHeader("hash", "")
                           .setHeader("clientId", 0)
                           .setHeader("eventType", "deleteCharacter")
                           .setBody("", "")
                           .build();
            networkManager_.sendResponse(passedClientData.socket,
                                         networkManager_.generateResponseMessage("error", response));
            return;
        }

        int characterId = passedClientData.characterData.characterId;
        if (characterId <= 0)
        {
            response = builder
                           .setHeader("message", "ERR_INVALID_CHARACTER_ID")
                           .setHeader("hash", passedClientData.hash)
                           .setHeader("clientId", passedClientData.clientId)
                           .setHeader("eventType", "deleteCharacter")
                           .setBody("", "")
                           .build();
            networkManager_.sendResponse(passedClientData.socket,
                                         networkManager_.generateResponseMessage("error", response));
            return;
        }

        auto poolGuard = pool_.acquire();
        bool deleted = characterManager_.deleteCharacter(
            poolGuard.get(), passedClientData.clientId, characterId);

        if (!deleted)
        {
            response = builder
                           .setHeader("message", "ERR_CHARACTER_NOT_FOUND")
                           .setHeader("hash", passedClientData.hash)
                           .setHeader("clientId", passedClientData.clientId)
                           .setHeader("eventType", "deleteCharacter")
                           .setBody("", "")
                           .build();
            networkManager_.sendResponse(passedClientData.socket,
                                         networkManager_.generateResponseMessage("error", response));
            return;
        }

        response = builder
                       .setHeader("message", "Character deleted successfully")
                       .setHeader("hash", passedClientData.hash)
                       .setHeader("clientId", passedClientData.clientId)
                       .setHeader("eventType", "deleteCharacter")
                       .setBody("characterId", characterId)
                       .build();
        networkManager_.sendResponse(passedClientData.socket,
                                     networkManager_.generateResponseMessage("success", response));
    }
    catch (const std::bad_variant_access &ex)
    {
        logger_.log("handleDeleteCharacterEvent error: " + std::string(ex.what()));
    }
}

void EventHandler::dispatchEvent(const Event &event, ClientData &clientData)
{
    switch (event.getType())
    {
    case Event::PING_CLIENT:
        handlePingClientEvent(event, clientData);
        break;
    case Event::AUTH_CLIENT:
        handleAuthentificateClientEvent(event, clientData);
        break;
    case Event::REGISTER_ACCOUNT:
        handleRegisterAccountEvent(event, clientData);
        break;
    case Event::GET_CHARACTERS_LIST:
        handleGetCharactersListEvent(event, clientData);
        break;
    case Event::CREATE_CHARACTER:
        handleCreateCharacterEvent(event, clientData);
        break;
    case Event::DELETE_CHARACTER:
        handleDeleteCharacterEvent(event, clientData);
        break;
    case Event::GET_CHARACTER_CREATION_OPTIONS:
        handleGetCharacterCreationOptionsEvent(event, clientData);
        break;
    case Event::DISCONNECT_CLIENT:
        handleDisconnectClientEvent(event, clientData);
        break;
    }
}