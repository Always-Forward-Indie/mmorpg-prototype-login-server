#include "events/Event.hpp"

Event::Event(EventType type, int clientID, const EventData data, std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket)
    : type(type), clientID(clientID), eventData(data), currentClientSocket(clientSocket), hasTimestamps_(false)
{
}

// Getter for clientID
int Event::getClientID() const
{
    return clientID;
}

// Getter for data
const EventData Event::getData() const
{
    return eventData;
}

// Getter for type
Event::EventType Event::getType() const
{
    return type;
}

// Getter for clientSocket
std::shared_ptr<boost::asio::ip::tcp::socket> Event::getClientSocket() const
{
    return currentClientSocket;
}

// Getter for timestamps
const TimestampStruct &Event::getTimestamps() const
{
    if (!hasTimestamps_)
    {
        throw std::runtime_error("Event does not have timestamps");
    }
    return timestamps_;
}

// Setter for timestamps
void Event::setTimestamps(const TimestampStruct &timestamps)
{
    timestamps_ = timestamps;
    hasTimestamps_ = true;
}

// Check if event has timestamps
bool Event::hasTimestamps() const
{
    return hasTimestamps_;
}