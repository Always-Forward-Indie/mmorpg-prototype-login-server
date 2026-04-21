#pragma once

#include <iostream>
#include <pqxx/pqxx>
#include <vector>
#include <data/ClientData.hpp>
#include <utils/Logger.hpp>

/// Error codes returned by createCharacter.
/// Negative values indicate failure; positive = new character id.
enum class CharacterCreateResult : int
{
    ERR_MISSING_FIELD = -1, ///< One or more required fields are empty
    ERR_NAME_INVALID = -2,  ///< Name format check failed
    ERR_NAME_TAKEN = -3,    ///< Name already in use
    ERR_SLOT_FULL = -4,     ///< Account has reached max character limit
    ERR_DB = -5,            ///< Database / internal error
};

static constexpr int MAX_CHARS_PER_ACCOUNT = 4;

class CharacterManager
{
public:
    // Constructor
    CharacterManager(Logger &logger);

    // Method to get characters list
    std::vector<CharacterDataStruct> getCharactersList(pqxx::connection &conn, ClientData &clientData, int accountId);

    /// Fetch equipped items for a single character for the character-selection preview.
    std::vector<EquipmentPreviewItemStruct> getCharacterEquipmentPreview(pqxx::connection &conn, int characterId);

    // Method to select a character
    CharacterDataStruct selectCharacter(pqxx::connection &conn, ClientData &clientData, int accountId, int characterId);

    /// Create a new character.
    /// On success returns the new character id (> 0).
    /// On failure returns one of the CharacterCreateResult negative codes.
    int createCharacter(pqxx::connection &conn, int accountId,
                        const std::string &characterName,
                        const std::string &characterClass,
                        const std::string &characterRace,
                        const std::string &characterGender);

    /// Soft-delete a character. Returns true on success, false if not found or owner mismatch.
    bool deleteCharacter(pqxx::connection &conn, int accountId, int characterId);

private:
    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
};
