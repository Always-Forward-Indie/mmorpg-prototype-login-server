#pragma once

#include <string>
#include <unordered_map>
#include <mutex>
#include <variant>
#include <boost/asio.hpp>
#include <nlohmann/json.hpp>
#include "data/DataStructs.hpp"

// Define the types of data that can be sent in an event
using EventData = std::variant<int, float, std::string, nlohmann::json, PositionStruct, CharacterDataStruct, ClientDataStruct /* other types */>;

class Event {
public:
    enum EventType { AUTH_CLIENT, DISCONNECT_CLIENT, GET_CHARACTERS_LIST, CREATE_CHARACTER, DELETE_CHARACTER}; // Define more event types as needed
    Event() = default; // Default constructor
    Event(EventType type, int clientID, const EventData data, std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket);
   // Event(EventType type, int clientID, const EventData data);

    // Get Event Data
    const EventData getData() const;
    // Get Client ID
    int getClientID() const;
    // Get Client Socket
    std::shared_ptr<boost::asio::ip::tcp::socket> getClientSocket() const;
    //Get Event Type
    EventType getType() const;

private:
    int clientID;
    EventType type;
    EventData eventData;
    std::shared_ptr<boost::asio::ip::tcp::socket> currentClientSocket;
};