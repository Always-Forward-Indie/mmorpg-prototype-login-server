#include "services/Authenticator.hpp"
#include "services/AccountManager.hpp"
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <spdlog/logger.h>
#include <string>
#include <pqxx/pqxx>

AuthOutcome Authenticator::authenticate(pqxx::connection &conn, ClientData &clientData, const std::string &login, const std::string &password, const std::string &clientIp, const std::string &clientVersion, Logger &logger)
{
    auto log = logger.getSystem("auth");
    try
    {
        // Step 1: fetch user row by login only (is_active check + lock check is in SQL)
        pqxx::work transaction(conn);
        pqxx::result getUserDBData = transaction.exec_prepared("search_user", login);

        if (getUserDBData.empty())
        {
            // Distinguish LOCKED/inactive from wrong login without leaking
            // existence to the client (wire stays generic; logs/metrics differ).
            AuthOutcome::Status status = AuthOutcome::Status::INVALID_CREDENTIALS;
            try
            {
                pqxx::work probe(conn);
                pqxx::result probeRow = probe.exec_prepared("probe_user_status", login);
                if (!probeRow.empty())
                {
                    bool active = probeRow[0]["is_active"].as<bool>();
                    bool locked = !probeRow[0]["locked_until"].is_null();
                    if (!active || locked)
                    {
                        status = AuthOutcome::Status::LOCKED;
                        log->warn("authenticate: locked/inactive login attempt login=" + login);
                    }
                }
                probe.abort(); // read-only
            }
            catch (const std::exception &probeEx)
            {
                log->warn("authenticate: status probe failed: " + std::string(probeEx.what()));
            }
            transaction.abort();
            return AuthOutcome{status, 0};
        }

        const auto &row = getUserDBData[0];
        int userID = row["id"].as<int>();
        std::string storedPassword = row["password"].as<std::string>();
        int role = row["role"].is_null() ? 0 : row["role"].as<int>();

        // Step 2: verify password (stored as SHA-256 hex, must hash the incoming plaintext).
        const std::string hashedInput = AccountManager::hashPassword(password);
        if (storedPassword != hashedInput)
        {
            // Increment failed login counter (may lock the account after 5 attempts).
            // Committed in the same txn as the read; concurrent bursts may both
            // increment from the same base (write-skew) — tolerable for a counter,
            // lock still engages (see increment_failed_logins CASE).
            transaction.exec_prepared("increment_failed_logins", login);
            transaction.commit();
            log->info("authenticate: wrong password login=" + login);
            return AuthOutcome{AuthOutcome::Status::INVALID_CREDENTIALS, 0};
        }

        // Step 3: reset failed login counter and update last_login
        const std::string ipStr = clientIp.empty() ? "127.0.0.1" : clientIp;
        transaction.exec_prepared("reset_failed_logins", userID, ipStr, clientVersion);
        transaction.commit();

        // Step 3b: manual GM ban (user_bans, with reason). Checked only after
        // a correct password so bans don't leak account existence.
        {
            pqxx::work banTxn(conn);
            pqxx::result banRow = banTxn.exec_prepared("check_active_ban", userID);
            banTxn.abort(); // read-only
            if (!banRow.empty())
            {
                AuthOutcome banned{AuthOutcome::Status::BANNED, 0};
                banned.banReason = banRow[0]["reason"].as<std::string>();
                banned.banExpiresAt = banRow[0]["expires_at"].as<std::string>();
                log->warn("authenticate: banned login attempt login=" + login);
                return banned;
            }
        }

        // Step 4: generate session token
        boost::uuids::uuid uuid = boost::uuids::random_generator()();
        std::string uniqueHash = boost::uuids::to_string(uuid);

        pqxx::work sessionTxn(conn);
        // Revoke all existing active sessions for this user before creating a new one.
        sessionTxn.exec_prepared("revoke_user_sessions", userID);
        // Clean up expired sessions to prevent unbounded growth.
        sessionTxn.exec_prepared("cleanup_expired_sessions");
        sessionTxn.exec_prepared("create_user_session", userID, uniqueHash, clientVersion);
        sessionTxn.commit();

        // Step 5: store in-memory client data
        ClientDataStruct clientDataStruct;
        clientDataStruct.clientId = userID;
        clientDataStruct.login = login;
        clientDataStruct.hash = uniqueHash;
        clientDataStruct.role = role;
        clientDataStruct.clientVersion = clientVersion;

        clientData.storeClientData(clientDataStruct);
        return AuthOutcome{AuthOutcome::Status::OK, userID};
    }
    catch (const std::exception &e)
    {
        // DB outage previously looked identical to wrong password (return 0).
        // Now triaged so operators/metrics can tell them apart.
        log->error("authenticate: database error: " + std::string(e.what()));
        return AuthOutcome{AuthOutcome::Status::DB_ERROR, 0};
    }
}
