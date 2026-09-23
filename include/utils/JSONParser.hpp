#pragma once
#include <nlohmann/json.hpp>
#include <array>
#include "data/DataStructs.hpp"
#include "utils/ProtocolLimits.hpp"

class JSONParser
{
private:
    static constexpr size_t max_length = protocol::kMaxMessageBytes;

public:
    JSONParser();
    ~JSONParser();
    
    CharacterDataStruct parseCharacterData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    PositionStruct parsePositionData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    ClientDataStruct parseClientData(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    MessageStruct parseMessage(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    std::string parseEventType(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    nlohmann::json parseCharactersList(const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    // Single-parse overloads: NetworkManager parses the wire bytes once and
    // threads the json through these (6-7 parses/message -> 1). Buffer
    // overloads above parse once and delegate here (kept for tests).
    CharacterDataStruct parseCharacterData(const nlohmann::json &jsonData);
    PositionStruct parsePositionData(const nlohmann::json &jsonData);
    ClientDataStruct parseClientData(const nlohmann::json &jsonData);
    MessageStruct parseMessage(const nlohmann::json &jsonData);
    std::string parseEventType(const nlohmann::json &jsonData);
};