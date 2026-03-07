#include <iostream>
#include <csignal>
#include <atomic>
#include "utils/Config.hpp"
#include "utils/Logger.hpp"
#include "login_server/LoginServer.hpp"
#include "utils/DatabasePool.hpp"
#include "services/CharacterManager.hpp"

std::atomic<bool> running(true);

void signalHandler(int signal)
{
    running = false;
}

int main()
{
    Logger logger("login-server");
    try
    {
        // Initialize the config
        Config config;

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

        // Initialize DatabasePool (5 connections, each with prepared queries)
        DatabasePool pool(std::get<0>(configs), logger);

        // Initialize the server
        LoginServer loginServer(clientData, eventQueueLoginServer, networkManager, pool, characterManager, logger);

        // Start accepting connections
        // networkManager.startAccept();

        // Start the IO Networking event loop
        networkManager.startIOEventLoop();

        // Start the main event loop
        loginServer.startMainEventLoop();

        while (running)
        {
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }

        return 0;
    }
    catch (const std::exception &e)
    {
        logger.critical("Fatal error: " + std::string(e.what()));
        return 1;
    }
}