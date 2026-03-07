#pragma once

#include <iostream>
#include <pqxx/pqxx>
#include <vector>
#include <data/ClientData.hpp>
#include <utils/Logger.hpp>

class CharacterManager
{
public:
    // Constructor
    CharacterManager(Logger &logger);

    // Method to get characters list
    std::vector<CharacterDataStruct> getCharactersList(pqxx::connection &conn, ClientData &clientData, int accountId);

    // Method to select a character
    CharacterDataStruct selectCharacter(pqxx::connection &conn, ClientData &clientData, int accountId, int characterId);

    // Method to create a character
    // Returns the new character id on success, 0 on failure.
    int createCharacter(pqxx::connection &conn, int accountId,
                        const std::string &characterName,
                        const std::string &characterClass,
                        const std::string &characterRace,
                        const std::string &characterGender);

    // Method to delete a character
    void deleteCharacter(pqxx::connection &conn, int accountId, int characterId);

private:
    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
};