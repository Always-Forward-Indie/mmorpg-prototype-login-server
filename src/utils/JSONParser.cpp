#include "utils/JSONParser.hpp"
#include <iostream>

JSONParser::JSONParser()
{
}

JSONParser::~JSONParser()
{
}

CharacterDataStruct JSONParser::parseCharacterData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    CharacterDataStruct characterData;

    // ... parse jsonData to CharacterData ...
    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterId") && 
    jsonData["body"]["characterId"].is_number_integer()) {
        characterData.characterId = jsonData["body"]["characterId"].get<int>();
    }

    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterLevel") && 
    jsonData["body"]["characterLevel"].is_number_integer()) {
        characterData.characterLevel = jsonData["body"]["characterLevel"].get<int>();
    }

    if (jsonData.contains("body") &&
    jsonData["body"].is_object() &&
    jsonData["body"].contains("characterExp") &&
    jsonData["body"]["characterExp"].is_number_integer()) {
        characterData.characterExperiencePoints = jsonData["body"]["characterExp"].get<int>();
    }

    if (jsonData.contains("body") &&
    jsonData["body"].is_object() &&
    jsonData["body"].contains("characterCurrentHealth") &&
    jsonData["body"]["characterCurrentHealth"].is_number_integer()) {
        characterData.characterCurrentHealth = jsonData["body"]["characterCurrentHealth"].get<int>();
    }

    if (jsonData.contains("body") &&
    jsonData["body"].is_object() &&
    jsonData["body"].contains("characterCurrentMana") &&
    jsonData["body"]["characterCurrentMana"].is_number_integer()) {
        characterData.characterCurrentMana = jsonData["body"]["characterCurrentMana"].get<int>();
    }

    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterName") && 
    jsonData["body"]["characterName"].is_string()) {
        characterData.characterName = jsonData["body"]["characterName"].get<std::string>();
    }

    if(jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterClass") && 
    jsonData["body"]["characterClass"].is_string()) {
        characterData.characterClass = jsonData["body"]["characterClass"].get<std::string>();
    }

    if(jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterRace") && 
    jsonData["body"]["characterRace"].is_string()) {
        characterData.characterRace = jsonData["body"]["characterRace"].get<std::string>();
    }


    return characterData;
}

PositionStruct JSONParser::parsePositionData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    PositionStruct positionData;

    // ... parse jsonData to PositionData ...
    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterPosX") && 
    jsonData["body"]["characterPosX"].is_number_float() || jsonData["body"]["characterPosX"].is_number_integer()) {
        positionData.positionX = jsonData["body"]["characterPosX"].get<float>();
    }

    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterPosY") && 
    jsonData["body"]["characterPosY"].is_number_float() || jsonData["body"]["characterPosY"].is_number_integer()) {
        positionData.positionY = jsonData["body"]["characterPosY"].get<float>();
    }

    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("characterPosZ") && 
    jsonData["body"]["characterPosZ"].is_number_float() || jsonData["body"]["characterPosZ"].is_number_integer()) {
        positionData.positionZ = jsonData["body"]["characterPosZ"].get<float>();
    }

    return positionData;
}

ClientDataStruct JSONParser::parseClientData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    ClientDataStruct clientData;

    // ... parse jsonData to ClientData ...
    if (jsonData.contains("header") && 
    jsonData["header"].is_object() && 
    jsonData["header"].contains("clientId") && 
    jsonData["header"]["clientId"].is_number_integer()) {
        clientData.clientId = jsonData["header"]["clientId"].get<int>();
    }

    if (jsonData.contains("header") && 
    jsonData["header"].is_object() && 
    jsonData["header"].contains("hash") && 
    jsonData["header"]["hash"].is_string()) {
        clientData.hash = jsonData["header"]["hash"].get<std::string>();
    }

    if (jsonData.contains("header") &&
    jsonData["header"].is_object() &&
    jsonData["header"].contains("login") &&
    jsonData["header"]["login"].is_string()) {
        clientData.login = jsonData["header"]["login"].get<std::string>();
    }

    if (jsonData.contains("header") &&
    jsonData["header"].is_object() &&
    jsonData["header"].contains("password") &&
    jsonData["header"]["password"].is_string()) {
        clientData.password = jsonData["header"]["password"].get<std::string>();
    }

    return clientData;
}

// parse characters list
nlohmann::json JSONParser::parseCharactersList(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    nlohmann::json charactersList;

    // ... parse jsonData to CharactersList ...
    if (jsonData.contains("body") && 
    jsonData["body"].is_object() && 
    jsonData["body"].contains("charactersList") && 
    jsonData["body"]["charactersList"].is_array()) {
        charactersList = jsonData["body"]["charactersList"];
        //charactersList = charactersJson.dump(); // Convert to string
        // Remove backslashes from the string
        //charactersList.erase(std::remove(charactersList.begin(), charactersList.end(), '\\'), charactersList.end());
    }

   return charactersList;
}

MessageStruct JSONParser::parseMessage(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    MessageStruct message;

    // ... parse jsonData to Message ...
    if (jsonData.contains("header") && 
    jsonData["header"].is_object() && 
    jsonData["header"].contains("status") && 
    jsonData["header"]["status"].is_string()) {
        message.status = jsonData["header"]["status"].get<std::string>();
    }

    if (jsonData.contains("header") && 
    jsonData["header"].is_object() && 
    jsonData["header"].contains("message") && 
    jsonData["header"]["message"].is_string()) {
        message.message = jsonData["header"]["message"].get<std::string>();
    }

    return message;
}

std::string JSONParser::parseEventType(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred)
{
    nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);
    std::string eventType;

    // ... parse jsonData to EventType ...
    if (jsonData.contains("header") && 
    jsonData["header"].is_object() && 
    jsonData["header"].contains("eventType") && 
    jsonData["header"]["eventType"].is_string()) {
        eventType = jsonData["header"]["eventType"].get<std::string>();
    }

    return eventType;
}