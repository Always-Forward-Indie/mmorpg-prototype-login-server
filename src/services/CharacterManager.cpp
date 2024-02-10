#include "services/CharacterManager.hpp"
#include "utils/Database.hpp"
#include <pqxx/pqxx>
#include <iostream>
#include <vector>

// Constructor
CharacterManager::CharacterManager()
{
    // Initialize properties or perform any setup here
}

// Method to get characters list
std::vector<CharacterDataStruct> CharacterManager::getCharactersList(Database &database, ClientData &clientData, int accountId)
{
    // initialize a vector of strings for characters
    std::vector<CharacterDataStruct> charactersList;
    // Create a CharacterDataStruct to save the character data from DB
    CharacterDataStruct characterDataStruct;

    try
    {
        pqxx::work transaction(database.getConnection()); // Start a transaction
        pqxx::result selectCharacterData = transaction.exec_prepared("get_characters_list", accountId);

        if (selectCharacterData.empty())
        {
            transaction.abort(); // Rollback the transaction
            return charactersList;
        }

        // Iterate through the result set and populate CharacterDataStruct objects
        for (const auto& row : selectCharacterData) {
            CharacterDataStruct characterDataStruct;
            characterDataStruct.characterId = row["character_id"].as<int>();
            characterDataStruct.characterLevel = row["character_lvl"].as<int>();
            characterDataStruct.characterName = row["character_name"].as<std::string>();
            characterDataStruct.characterClass = row["character_class"].as<std::string>();
            
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
CharacterDataStruct CharacterManager::selectCharacter(Database &database, ClientData &clientData, int accountId, int characterId)
{
    // Create a CharacterDataStruct to save the character data from DB
    CharacterDataStruct characterDataStruct;

    try
    {
        pqxx::work transaction(database.getConnection()); // Start a transaction
        pqxx::result selectCharacterData = transaction.exec_prepared("select_character", accountId, characterId);

        if (selectCharacterData.empty())
        {
            transaction.abort(); // Rollback the transaction
            return characterDataStruct;
        }

        // Loop through the result set and process the data
        for (pqxx::result::size_type i = 0; i < selectCharacterData.size(); ++i)
        {
            characterDataStruct.characterId = selectCharacterData[i][0].as<int>();            // Access the second column (index 1)
            characterDataStruct.characterLevel = selectCharacterData[i][1].as<int>();         // Access the second column (index 1)
            characterDataStruct.characterName = selectCharacterData[i][2].as<std::string>();  // Access the second column (index 1)
            characterDataStruct.characterClass = selectCharacterData[i][3].as<std::string>(); // Access the second column (index 1)
        }

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
void CharacterManager::createCharacter(Database &database, int accountId, const std::string &characterName, const std::string &characterClass)
{
    // Implement logic to create a character
}
