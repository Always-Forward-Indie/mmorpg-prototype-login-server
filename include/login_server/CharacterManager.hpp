#include <iostream>
#include <vector>
#include <helpers/Database.hpp>
#include <login_server/ClientData.hpp>

class CharacterManager {
public:
    // Constructor
    CharacterManager();

    // Method to get characters list
    std::vector<CharacterDataStruct> getCharactersList(Database& database, ClientData& clientData, int accountId);

    // Method to select a character
    CharacterDataStruct selectCharacter(Database& database, ClientData& clientData, int accountId, int characterId);

    // Method to create a character
    void createCharacter(Database& database, int accountId, const std::string& characterName, const std::string& characterClass);
};