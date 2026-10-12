// Authenticator.hpp
#pragma once

#include <pqxx/pqxx>
#include <string>
#include "data/ClientData.hpp"
#include "utils/Logger.hpp"

/// Triaged authentication outcome. Previously a bare `int` (0 = everything:
/// wrong password, locked account, DB down) so operators could not tell an
/// attack from an outage and clients got one generic message.
struct AuthOutcome {
    enum class Status {
        OK = 0,                 ///< authenticated; userId is valid
        INVALID_CREDENTIALS = 1, ///< unknown login, inactive, or wrong password
        LOCKED = 2,             ///< account temporarily locked (5 fails / 15 min)
        DB_ERROR = 3,           ///< database / internal error
        BANNED = 4,             ///< manual GM ban (user_bans, with reason+expiry)
    };
    Status status = Status::INVALID_CREDENTIALS;
    int userId = 0;
    std::string banReason;
    std::string banExpiresAt;
};

class Authenticator
{
public:
    AuthOutcome authenticate(pqxx::connection &conn, ClientData &clientData, const std::string &login, const std::string &password, const std::string &clientIp, const std::string &clientVersion, Logger &logger);
};
