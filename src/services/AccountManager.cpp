#include "services/AccountManager.hpp"

#include <spdlog/logger.h>
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <openssl/evp.h>
#include <iomanip>
#include <regex>
#include <sstream>
#include <string>
#include <pqxx/pqxx>

AccountManager::AccountManager(Logger &logger)
    : logger_(logger)
{
    log_ = logger.getSystem("account");
}

// ---------------------------------------------------------------------------
// Password hashing — SHA-256 hex string via OpenSSL EVP API.
// NOTE: SHA-256 is sufficient for a prototype. Migrate to argon2id before
//       any real user data is processed.
// ---------------------------------------------------------------------------
std::string AccountManager::hashPassword(const std::string &plaintext)
{
    unsigned char digest[EVP_MAX_MD_SIZE];
    unsigned int digestLen = 0;

    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
    EVP_DigestInit_ex(ctx, EVP_sha256(), nullptr);
    EVP_DigestUpdate(ctx, plaintext.data(), plaintext.size());
    EVP_DigestFinal_ex(ctx, digest, &digestLen);
    EVP_MD_CTX_free(ctx);

    std::ostringstream oss;
    for (unsigned int i = 0; i < digestLen; ++i)
        oss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(digest[i]);
    return oss.str();
}

// ---------------------------------------------------------------------------
// registerAccount
// ---------------------------------------------------------------------------
AccountRegisterResult AccountManager::registerAccount(pqxx::connection &conn,
                                                      ClientData &clientData,
                                                      const std::string &login,
                                                      const std::string &password,
                                                      const std::string &email,
                                                      const std::string &registrationIp,
                                                      int &outUserId,
                                                      std::string &outHash)
{
    // --- Input validation ---------------------------------------------------
    // Login: 3-20 chars, only A-Za-z0-9_
    static const std::regex loginRegex("^[A-Za-z0-9_]{3,20}$");
    if (!std::regex_match(login, loginRegex))
        return AccountRegisterResult::ERR_LOGIN_INVALID;

    if (password.size() < 8)
        return AccountRegisterResult::ERR_PASSWORD_SHORT;

    if (password.size() > 100)
        return AccountRegisterResult::ERR_PASSWORD_LONG;

    if (!email.empty() && email.find('@') == std::string::npos)
        return AccountRegisterResult::ERR_EMAIL_INVALID;

    try
    {
        // --- Uniqueness check -----------------------------------------------
        {
            pqxx::work txn(conn);
            pqxx::result r = txn.exec_prepared("check_login_available", login);
            txn.abort(); // read-only, no commit needed
            if (!r.empty())
                return AccountRegisterResult::ERR_LOGIN_TAKEN;
        }

        // --- Create account --------------------------------------------------
        const std::string passwordHash = hashPassword(password);
        const std::string ipStr = registrationIp.empty() ? "127.0.0.1" : registrationIp;

        pqxx::work txn(conn);
        pqxx::result insertResult = txn.exec_prepared(
            "register_user", login, passwordHash, email, ipStr);

        if (insertResult.empty())
        {
            txn.abort();
            log_->error("registerAccount: INSERT returned no row for login=" + login);
            return AccountRegisterResult::ERR_DB;
        }

        int userId = insertResult[0]["id"].as<int>();

        // --- Create session --------------------------------------------------
        boost::uuids::uuid uuid = boost::uuids::random_generator()();
        std::string sessionHash = boost::uuids::to_string(uuid);

        txn.exec_prepared("cleanup_expired_sessions");
        txn.exec_prepared("create_user_session", userId, sessionHash);
        txn.commit();

        // --- Populate in-memory client store --------------------------------
        ClientDataStruct data;
        data.clientId = userId;
        data.login = login;
        data.hash = sessionHash;
        clientData.storeClientData(data);

        outUserId = userId;
        outHash = sessionHash;

        log_->info("registerAccount: new account id=" + std::to_string(userId) + " login=" + login);
        return AccountRegisterResult::OK;
    }
    catch (const std::exception &e)
    {
        logger_.logError("registerAccount error: " + std::string(e.what()));
        return AccountRegisterResult::ERR_DB;
    }
}
