#pragma once

#include <iostream>
#include <vector>
#include <utils/Database.hpp>
#include <data/ClientData.hpp>
#include <utils/Logger.hpp>

class CharacterManager {
public:
    // Constructor
    CharacterManager(Logger& logger);

    // Method to get characters list
    std::vector<CharacterDataStruct> getCharactersList(Database& database, ClientData& clientData, int accountId);

    // Method to select a character
    CharacterDataStruct selectCharacter(Database& database, ClientData& clientData, int accountId, int characterId);

    // Method to create a character
    void createCharacter(Database& database, int accountId, const std::string& characterName, const std::string& characterClass);

    // Method to delete a character
    void deleteCharacter(Database& database, int accountId, int characterId);

private:
    Logger& logger_;
};