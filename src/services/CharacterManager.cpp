#include "services/CharacterManager.hpp"
#include <pqxx/pqxx>
#include <iostream>
#include <vector>
#include <spdlog/logger.h>

// Constructor
CharacterManager::CharacterManager(Logger &logger)
    : logger_(logger)
{
    log_ = logger.getSystem("character");
    // Initialize properties or perform any setup here
}

// Method to get characters list
std::vector<CharacterDataStruct> CharacterManager::getCharactersList(pqxx::connection &conn, ClientData &clientData, int accountId)
{
    // initialize a vector of strings for characters
    std::vector<CharacterDataStruct> charactersList;
    // Create a CharacterDataStruct to save the character data from DB
    CharacterDataStruct characterDataStruct;

    try
    {
        pqxx::work transaction(conn);
        pqxx::result selectCharacterData = transaction.exec_prepared("get_characters_list", accountId);

        if (selectCharacterData.empty())
        {
            transaction.abort(); // Rollback the transaction
            return charactersList;
        }

        // Iterate through the result set and populate CharacterDataStruct objects
        for (const auto &row : selectCharacterData)
        {
            CharacterDataStruct characterDataStruct;
            characterDataStruct.characterId = row["character_id"].as<int>();
            characterDataStruct.characterLevel = row["character_lvl"].as<int>();
            characterDataStruct.characterName = row["character_name"].as<std::string>();
            characterDataStruct.characterClass = row["character_class"].as<std::string>();
            characterDataStruct.characterRace = row["race_name"].as<std::string>();
            characterDataStruct.characterExperiencePoints = row["experience_points"].as<int>();
            characterDataStruct.characterCurrentHealth = row["current_health"].as<int>();
            characterDataStruct.characterCurrentMana = row["current_mana"].as<int>();

            // Add the populated CharacterDataStruct to the vector
            charactersList.push_back(characterDataStruct);
        }

        transaction.commit(); // Commit the transaction

        clientData.updateClientData(accountId, characterDataStruct); // Update clientData in the ClientData class
    }
    catch (const std::exception &e)
    {
        // Handle database connection or query errors
        std::cerr << "Database error: " << e.what() << std::endl;
        // You might want to send an error response back to the client or log the error
        return charactersList;
    }

    return charactersList;
}

// Method to select a character
CharacterDataStruct CharacterManager::selectCharacter(pqxx::connection &conn, ClientData &clientData, int accountId, int characterId)
{
    // Create a CharacterDataStruct to save the character data from DB
    CharacterDataStruct characterDataStruct;

    try
    {
        pqxx::work transaction(conn);
        pqxx::result selectCharacterData = transaction.exec_prepared("select_character", accountId, characterId);

        if (selectCharacterData.empty())
        {
            transaction.abort(); // Rollback the transaction
            return characterDataStruct;
        }

        // Map result by column name (robust against column order changes)
        const auto &row = selectCharacterData[0];
        characterDataStruct.characterId = row["character_id"].as<int>();
        characterDataStruct.characterLevel = row["character_lvl"].as<int>();
        characterDataStruct.characterName = row["character_name"].as<std::string>();
        characterDataStruct.characterClass = row["character_class"].as<std::string>();
        characterDataStruct.characterRace = row["race_name"].as<std::string>();
        characterDataStruct.characterExperiencePoints = row["experience_points"].as<int>();

        transaction.commit(); // Commit the transaction

        clientData.updateClientData(accountId, characterDataStruct); // Update clientData in the ClientData class
    }
    catch (const std::exception &e)
    {
        // Handle database connection or query errors
        std::cerr << "Database error: " << e.what() << std::endl;
        // You might want to send an error response back to the client or log the error
        return characterDataStruct;
    }

    return characterDataStruct;
}

// Method to create a character
// Returns the new character id on success, 0 on failure.
int CharacterManager::createCharacter(pqxx::connection &conn, int accountId,
                                      const std::string &characterName, const std::string &characterClass,
                                      const std::string &characterRace, const std::string &characterGender)
{
    if (characterName.empty() || characterClass.empty() || characterRace.empty() || characterGender.empty())
    {
        log_->info("createCharacter: missing required field");
        return 0;
    }

    try
    {
        pqxx::work transaction(conn); // Step 1: insert character row (class/race/gender resolved by name inside the query)
        pqxx::result createResult = transaction.exec_prepared(
            "create_character",
            accountId,
            characterName,
            characterClass,
            characterRace,
            characterGender);

        if (createResult.empty())
        {
            transaction.abort();
            log_->info("createCharacter: insert returned no row (class/race/gender name not found?)");
            return 0;
        }

        int newCharacterId = createResult[0]["id"].as<int>();

        // Step 2: initialise health/mana state
        transaction.exec_prepared("init_character_state", newCharacterId);

        // Step 3: initialise starting position (0,0,200 in zone 1 — village)
        transaction.exec_prepared("init_character_position", newCharacterId);

        transaction.commit();

        log_->info("createCharacter: created character id=" + std::to_string(newCharacterId) + " name=" + characterName);
        return newCharacterId;
    }
    catch (const std::exception &e)
    {
        logger_.log("createCharacter error: " + std::string(e.what()));
        return 0;
    }
}
