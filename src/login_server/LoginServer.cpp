#include "login_server/LoginServer.hpp"

LoginServer::LoginServer(ClientData &clientData,
EventQueue& eventQueueLoginServer, 
NetworkManager& networkManager, 
Database& database,
CharacterManager& characterManager,
Logger& logger) 
    : networkManager_(networkManager),
      clientData_(clientData),
      logger_(logger),
      eventQueueLoginServer_(eventQueueLoginServer),
      characterManager_(characterManager),
      eventHandler_(networkManager, database, characterManager, logger),
      database_(database)
{
    // Start accepting new clients connections
    networkManager_.startAccept();
}

void LoginServer::mainEventLoop() {
    logger_.log("Add Tasks To Scheduler...", YELLOW);

    //TODO work on this later
    //TODO - save different client data to the database in different time intervals (depend by the client data type)
    // Schedule tasks
    //scheduler_.scheduleTask({[&] { characterManager_.updateBasicCharactersData(database_, clientData_); }, 5, std::chrono::system_clock::now()}); // every 5 seconds

    logger_.log("Starting Login Server Event Loop...", YELLOW);
    while (true) {
        Event event;

        if (eventQueueLoginServer_.pop(event)) {
            eventHandler_.dispatchEvent(event, clientData_);
        }

        // Optionally include a small delay or yield to prevent the loop from consuming too much CPU
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
}

void LoginServer::startMainEventLoop()
{
    // Start the main event loop in a new thread
    event_thread_ = std::thread(&LoginServer::mainEventLoop, this);
}

// destructor
LoginServer::~LoginServer()
{
    logger_.log("Shutting down Login server...", YELLOW);
    // Stop the main event loop
    event_thread_.join();
}