#pragma once
#include <string>
#include <boost/asio.hpp>

/**
 * @brief Timestamp structure for lag compensation
 * Contains timing information for client-server communication and request synchronization
 */
struct TimestampStruct
{
    long long serverRecvMs = 0;     // When server received the packet (milliseconds since epoch)
    long long serverSendMs = 0;     // When server sends the response (milliseconds since epoch)
    long long clientSendMsEcho = 0; // Echo of client timestamp from original request (milliseconds since epoch)
    std::string requestId = "";     // Echo of client requestId for packet synchronization (format: sync_timestamp_session_sequence_hash)
};

struct PositionStruct
{
    float positionX = 0;
    float positionY = 0;
    float positionZ = 0;
    bool needDBUpdate = false;
};

struct CharacterDataStruct
{
    int characterId = 0;
    int characterLevel = 0;
    int characterExperiencePoints = 0;
    int characterCurrentHealth = 0;
    int characterCurrentMana = 0;
    std::string characterName = "";
    std::string characterClass = "";
    std::string characterRace = "";
    std::string characterGender = "";
    PositionStruct characterPosition;
    bool needDBUpdate = false;
};

struct ClientDataStruct
{
    int clientId = 0;
    std::string login = "";
    std::string password = "";
    std::string hash = "";
    std::shared_ptr<boost::asio::ip::tcp::socket> socket;
    CharacterDataStruct characterData;
    bool needDBUpdate = false;
};

struct MessageStruct
{
    std::string status = "";
    std::string message = "";
};

/// Payload carried by the REGISTER_ACCOUNT event.
struct RegistrationDataStruct
{
    std::string login = "";
    std::string password = "";
    std::string email = ""; // optional
    std::string registrationIp = "";
    std::shared_ptr<boost::asio::ip::tcp::socket> socket;
};

/// Single entry for character-creation option lists (class / race / gender).
struct CreationOptionStruct
{
    int id = 0;
    std::string name = "";
    std::string slug = "";        // empty for genders (use name)
    std::string label = "";       // display label, used by gender entries
    std::string description = ""; // optional, classes only
};