#include "services/CharacterManager.hpp"
#include <pqxx/pqxx>
#include <iostream>
#include <regex>
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
            characterDataStruct.characterClass = row["class_slug"].as<std::string>();
            characterDataStruct.characterRace = row["race_slug"].as<std::string>();
            characterDataStruct.characterGender = row["gender_slug"].is_null() ? "" : row["gender_slug"].as<std::string>();
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
// Returns the new character id (> 0) on success, or a negative CharacterCreateResult code on failure.
int CharacterManager::createCharacter(pqxx::connection &conn, int accountId,
                                      const std::string &characterName, const std::string &characterClass,
                                      const std::string &characterRace, const std::string &characterGender)
{
    // --- Field presence check -----------------------------------------------
    if (characterName.empty() || characterClass.empty() || characterRace.empty() || characterGender.empty())
    {
        log_->info("createCharacter: missing required field");
        return static_cast<int>(CharacterCreateResult::ERR_MISSING_FIELD);
    }

    // --- Name format validation (C++ side, before hitting DB) ---------------
    // Allowed: letters (A-Z a-z), spaces, apostrophes; 2-20 chars; no leading/trailing spaces; no double spaces
    static const std::regex nameRegex("^[A-Za-z][A-Za-z ']{0,18}[A-Za-z]$|^[A-Za-z]{1,20}$");
    if (!std::regex_match(characterName, nameRegex))
    {
        log_->info("createCharacter: invalid name format: " + characterName);
        return static_cast<int>(CharacterCreateResult::ERR_NAME_INVALID);
    }
    // Extra: no double spaces
    if (characterName.find("  ") != std::string::npos)
    {
        log_->info("createCharacter: double-space in name: " + characterName);
        return static_cast<int>(CharacterCreateResult::ERR_NAME_INVALID);
    }

    try
    {
        pqxx::work transaction(conn);

        // --- Slot limit check -----------------------------------------------
        pqxx::result slotResult = transaction.exec_prepared("get_character_slot_count", accountId);
        if (!slotResult.empty())
        {
            int slotCount = slotResult[0][0].as<int>();
            if (slotCount >= MAX_CHARS_PER_ACCOUNT)
            {
                transaction.abort();
                log_->info("createCharacter: slot limit reached for account=" + std::to_string(accountId));
                return static_cast<int>(CharacterCreateResult::ERR_SLOT_FULL);
            }
        }

        // --- Name uniqueness check ------------------------------------------
        pqxx::result nameCheck = transaction.exec_prepared("check_character_name_exists", characterName);
        if (!nameCheck.empty())
        {
            transaction.abort();
            log_->info("createCharacter: name already taken: " + characterName);
            return static_cast<int>(CharacterCreateResult::ERR_NAME_TAKEN);
        }

        // --- Insert character row -------------------------------------------
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
            return static_cast<int>(CharacterCreateResult::ERR_DB);
        }

        int newCharacterId = createResult[0]["id"].as<int>();

        // --- Resolve class_id (needed for skills + starter items) -----------
        pqxx::result classResult = transaction.exec_prepared("get_class_id_by_name", characterClass);
        int classId = classResult.empty() ? 0 : classResult[0]["id"].as<int>();

        // --- Init health/mana state -----------------------------------------
        transaction.exec_prepared("init_character_state", newCharacterId);

        // --- Init starting position -----------------------------------------
        transaction.exec_prepared("init_character_position", newCharacterId);

        // --- Grant default skills -------------------------------------------
        if (classId > 0)
            transaction.exec_prepared("init_character_default_skills", newCharacterId, classId);

        // --- Grant starter items --------------------------------------------
        if (classId > 0)
            transaction.exec_prepared("init_character_starter_items", newCharacterId, classId);

        transaction.commit();

        log_->info("createCharacter: created id=" + std::to_string(newCharacterId) + " name=" + characterName + " class=" + characterClass);
        return newCharacterId;
    }
    catch (const std::exception &e)
    {
        logger_.log("createCharacter error: " + std::string(e.what()));
        return static_cast<int>(CharacterCreateResult::ERR_DB);
    }
}

// Soft-delete a character.
// Returns true if the character was found and belongs to accountId; false otherwise.
bool CharacterManager::deleteCharacter(pqxx::connection &conn, int accountId, int characterId)
{
    try
    {
        pqxx::work transaction(conn);
        pqxx::result result = transaction.exec_prepared("delete_character", characterId, accountId);
        transaction.commit();

        if (result.empty())
        {
            log_->info("deleteCharacter: not found or owner mismatch — charId=" + std::to_string(characterId) + " accountId=" + std::to_string(accountId));
            return false;
        }

        log_->info("deleteCharacter: soft-deleted charId=" + std::to_string(characterId));
        return true;
    }
    catch (const std::exception &e)
    {
        logger_.log("deleteCharacter error: " + std::string(e.what()));
        return false;
    }
}

std::vector<EquipmentPreviewItemStruct> CharacterManager::getCharacterEquipmentPreview(pqxx::connection &conn, int characterId)
{
    std::vector<EquipmentPreviewItemStruct> equipment;
    try
    {
        pqxx::work txn(conn);
        pqxx::result rows = txn.exec_prepared("get_character_equipment_preview", characterId);
        txn.commit();

        equipment.reserve(rows.size());
        for (const auto &row : rows)
        {
            EquipmentPreviewItemStruct item;
            item.slotId = row["slot_id"].as<int>();
            item.itemSlug = row["item_slug"].as<std::string>();
            equipment.push_back(item);
        }
    }
    catch (const std::exception &e)
    {
        logger_.log("getCharacterEquipmentPreview error: " + std::string(e.what()));
    }
    return equipment;
}
