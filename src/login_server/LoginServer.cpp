#include "login_server/LoginServer.hpp"

LoginServer::LoginServer(ClientData &clientData,
                         EventQueue &eventQueueLoginServer,
                         NetworkManager &networkManager,
                         Database &database,
                         CharacterManager &characterManager,
                         Logger &logger)
    : networkManager_(networkManager),
      clientData_(clientData),
      logger_(logger),
      eventQueueLoginServer_(eventQueueLoginServer),
      characterManager_(characterManager),
      eventHandler_(networkManager, database, characterManager, logger),
      database_(database)
{
}

void LoginServer::processBatch(const std::vector<Event> &eventsBatch)
{
    std::vector<Event> priorityEvents;
    std::vector<Event> normalEvents;

    // Separate ping events from other events
    for (const auto &event : eventsBatch)
    {
        // if (event.PING_CLIENT == Event::PING_CLIENT)
        //     priorityEvents.push_back(event);
        // else
        normalEvents.push_back(event);
    }

    // Process priority ping events first
    for (const auto &event : priorityEvents)
    {
        // Create a deep copy of the event to ensure its data remains valid
        // when processed asynchronously in the thread pool
        Event eventCopy = event;
        threadPool_.enqueueTask([this, eventCopy]
                                {
            try
            {
                eventHandler_.dispatchEvent(eventCopy, clientData_);
            }
            catch (const std::exception &e)
            {
                logger_.logError("Error processing priority dispatchEvent: " + std::string(e.what()));
            } });
    }

    // Process normal events
    for (const auto &event : normalEvents)
    {
        // Create a deep copy of the event to ensure its data remains valid
        // when processed asynchronously in the thread pool
        Event eventCopy = event;
        threadPool_.enqueueTask([this, eventCopy]
                                {
            try
            {
                eventHandler_.dispatchEvent(eventCopy, clientData_);
            }
            catch (const std::exception &e)
            {
                logger_.logError("Error in normal dispatchEvent: " + std::string(e.what()));
            } });
    }

    eventCondition.notify_all();
}

void LoginServer::mainEventLoop()
{
    logger_.log("Add Tasks To Login Server Scheduler...", YELLOW);
    constexpr int BATCH_SIZE = 10;

    try
    {
        logger_.log("Starting Login Server Event Loop...", YELLOW);
        while (running_)
        {
            std::vector<Event> eventsBatch;
            if (eventQueueLoginServer_.popBatch(eventsBatch, BATCH_SIZE))
            {
                processBatch(eventsBatch);
            }
        }
    }
    catch (const std::exception &e)
    {
        logger_.logError(e.what(), RED);
    }
}

void LoginServer::startMainEventLoop()
{
    // Start the main event loop in a new thread
    if (event_thread_.joinable())
    {
        logger_.log("Login server event loops are already running!", RED);
        return;
    }

    event_thread_ = std::thread(&LoginServer::mainEventLoop, this);
}

void LoginServer::stop()
{
    running_ = false;
    eventCondition.notify_all();
}

// destructor
LoginServer::~LoginServer()
{
    logger_.log("Shutting down Login server...", YELLOW);
    // Stop the main event loop
    event_thread_.join();

    if (event_thread_.joinable())
        event_thread_.join();
}