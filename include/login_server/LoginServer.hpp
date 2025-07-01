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
#include "utils/ThreadPool.hpp"
#include "services/CharacterManager.hpp"

class LoginServer
{
public:
    LoginServer(ClientData &clientData,
                EventQueue &eventQueueLoginServer,
                NetworkManager &networkManager,
                Database &database,
                CharacterManager &characterManager,
                Logger &logger);
    ~LoginServer();
    void startMainEventLoop();

private:
    // Events
    void mainEventLoop();

    void processBatch(const std::vector<Event> &eventsBatch);
    void processPingBatch(const std::vector<Event> &pingEvents);

    void stop();
    bool running_ = true; // Flag to control the main event loop
    std::condition_variable eventCondition;
    ThreadPool threadPool_{std::thread::hardware_concurrency()};

    std::thread event_thread_;
    ClientData &clientData_;
    Logger &logger_;
    EventQueue &eventQueueLoginServer_;
    EventHandler eventHandler_;
    NetworkManager &networkManager_;
    CharacterManager &characterManager_;
    Database &database_;
};
