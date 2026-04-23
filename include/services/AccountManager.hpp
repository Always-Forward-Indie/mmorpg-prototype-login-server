#pragma once

#include <string>
#include <pqxx/pqxx>
#include "data/ClientData.hpp"
#include "utils/Logger.hpp"

/// Error codes returned by AccountManager methods.
/// Negative values are errors; 0 = failure (should not be returned directly, use codes below).
enum class AccountRegisterResult : int
{
    OK = 0,                  ///< Success — userId is valid
    ERR_LOGIN_INVALID = -1,  ///< Login format: 3-20 chars, [A-Za-z0-9_] only
    ERR_LOGIN_TAKEN = -2,    ///< Login already registered (case-insensitive)
    ERR_PASSWORD_SHORT = -3, ///< Password shorter than 8 characters
    ERR_PASSWORD_LONG = -4,  ///< Password longer than 100 characters
    ERR_EMAIL_INVALID = -5,  ///< Email provided but malformed (no '@')
    ERR_DB = -6,             ///< Database / internal error
};

class AccountManager
{
public:
    explicit AccountManager(Logger &logger);

    /// Register a new account.
    /// On success sets userId and sessionHash in output params and returns AccountRegisterResult::OK.
    /// On failure returns a negative AccountRegisterResult code; output params are unchanged.
    ///
    /// @param conn          Live pooled DB connection
    /// @param clientData    In-memory client store (updated on success)
    /// @param login         Raw login string from client
    /// @param password      Raw password string from client (will be hashed here)
    /// @param email         Optional email (pass empty string to skip)
    /// @param registrationIp  Client IP address string for audit
    /// @param outUserId     [out] new user ID on success
    /// @param outHash       [out] session token on success
    AccountRegisterResult registerAccount(pqxx::connection &conn,
                                          ClientData &clientData,
                                          const std::string &login,
                                          const std::string &password,
                                          const std::string &email,
                                          const std::string &registrationIp,
                                          int &outUserId,
                                          std::string &outHash);

    /// SHA-256 hex digest of plaintext. Used for both registration and login verification.
    /// TODO: migrate to bcrypt/argon2 for production security.
    static std::string hashPassword(const std::string &plaintext);

private:
    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
};
