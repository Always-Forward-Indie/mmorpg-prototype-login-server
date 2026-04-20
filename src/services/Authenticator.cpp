#include "services/Authenticator.hpp"
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <string>
#include <pqxx/pqxx>
#include <iostream>

int Authenticator::authenticate(pqxx::connection &conn, ClientData &clientData, const std::string &login, const std::string &password)
{
    try
    {
        // Step 1: fetch user row by login only (is_active check + lock check is in SQL)
        pqxx::work transaction(conn);
        pqxx::result getUserDBData = transaction.exec_prepared("search_user", login);

        if (getUserDBData.empty())
        {
            transaction.abort();
            return 0;
        }

        const auto &row = getUserDBData[0];
        int userID = row["id"].as<int>();
        std::string storedPassword = row["password"].as<std::string>();

        // Step 2: verify password.
        // NOTE: The stored password is currently a plain string (legacy).
        // TODO: migrate to bcrypt/argon2 hashing and update this comparison.
        if (storedPassword != password)
        {
            // Increment failed login counter (may lock the account after 5 attempts)
            transaction.exec_prepared("increment_failed_logins", login);
            transaction.commit();
            return 0;
        }

        // Step 3: reset failed login counter and update last_login
        transaction.exec_prepared("reset_failed_logins", userID, "127.0.0.1");
        transaction.commit();

        // Step 4: generate session token
        boost::uuids::uuid uuid = boost::uuids::random_generator()();
        std::string uniqueHash = boost::uuids::to_string(uuid);

        pqxx::work sessionTxn(conn);
        // Clean up expired sessions before creating a new one to prevent unbounded growth.
        sessionTxn.exec_prepared("cleanup_expired_sessions");
        sessionTxn.exec_prepared("create_user_session", userID, uniqueHash);
        sessionTxn.commit();

        // Step 5: store in-memory client data
        ClientDataStruct clientDataStruct;
        clientDataStruct.clientId = userID;
        clientDataStruct.login = login;
        clientDataStruct.hash = uniqueHash;

        clientData.storeClientData(clientDataStruct);
        return userID;
    }
    catch (const std::exception &e)
    {
        std::cerr << "Database error: " << e.what() << std::endl;
        return 0;
    }
}