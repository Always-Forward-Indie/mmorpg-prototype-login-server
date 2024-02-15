#pragma once
#include <array>
#include <string>
#include <iostream>
#include <chrono>
#include <thread>
#include "network/NetworkManager.hpp"
#include "events/Event.hpp"
#include "events/EventQueue.hpp"
#include "events/EventHandler.hpp"
#include "utils/Logger.hpp"
#include "services/CharacterManager.hpp"

class LoginServer {
public:
    LoginServer(ClientData &clientData,
    EventQueue& eventQueueLoginServer, 
    NetworkManager& networkManager, 
    Database& database,
    CharacterManager& characterManager,
    Logger& logger);
    ~LoginServer();
    void startMainEventLoop();
    
private:
    //Events
    void mainEventLoop();

    std::thread event_thread_;
    ClientData& clientData_;
    Logger& logger_;
    EventQueue& eventQueueLoginServer_;
    EventHandler eventHandler_;
    NetworkManager& networkManager_;
    CharacterManager& characterManager_;
    Database& database_;
};
