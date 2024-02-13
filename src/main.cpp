#include <iostream>
#include "utils/Config.hpp"
#include "utils/Logger.hpp"
#include "login_server/LoginServer.hpp"
#include "utils/Database.hpp"
#include "services/CharacterManager.hpp"

//TODO complete basic refactoring
//TODO implement events functionality to the server and move the logic to the events
int main() {
    try {
        // Initialize the config
        Config config;
        // Initialize Logger
        Logger logger;

        // Parse the config file
        auto configs = config.parseConfig("config.json");

        // Initialize ClientData
        ClientData clientData;

        // Initialize EventQueue
        EventQueue eventQueueLoginServer;

        // Initialize NetworkManager
        NetworkManager networkManager(eventQueueLoginServer, configs, logger);

        // Initialize CharacterManager
        CharacterManager characterManager(logger);

        // Initialize Database
        Database database(configs, logger);

        // Initialize the server
        LoginServer loginServer(clientData, eventQueueLoginServer, networkManager, database, characterManager, logger);

        loginServer.startMainEventLoop();

        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;  // Indicate an error exit status
    }
}