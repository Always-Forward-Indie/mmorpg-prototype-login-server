#include "login_server/Authenticator.hpp"
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <string>
#include <pqxx/pqxx>
#include <iostream>

// Add these using declarations for convenience
using namespace pqxx;
using namespace std;

bool Authenticator::authenticate(const std::string& login, const std::string& password, const std::string& hash, ClientData& clientData) {
    try {
        // Create a PostgreSQL database connection
        pqxx::connection connection("dbname=mmo_prototype user=postgres password=root hostaddr=127.0.0.1 port=5432");

        connection.prepare("search_user", "SELECT * FROM users WHERE login = $1 AND password = $2 LIMIT 1;");

        // Check if the provided login and password match a record in the database
        pqxx::work transaction(connection);
        pqxx::result getUserDBData = transaction.exec_prepared("search_user", login, password);

        if (!getUserDBData.empty()) {
            int userID = 0;

            // Loop through the result set and process the data
            for (pqxx::result::size_type i = 0; i < getUserDBData.size(); ++i) {
                userID = getUserDBData[i][0].as<int>(); // Access the second column (index 1)
            }

           // transaction.commit(); // Commit the transaction

            // Generate a unique hash for the client
            boost::uuids::uuid uuid = boost::uuids::random_generator()();
            std::string uniqueHash = boost::uuids::to_string(uuid);

            // Create a ClientDataStruct with the login, password, and unique hash
            ClientDataStruct clientDataStruct;
            clientDataStruct.clientId = userID;
            clientDataStruct.login = login;
            clientDataStruct.hash = uniqueHash;

            connection.prepare("update_user", "UPDATE users SET session_key = $1 WHERE id = $2;");

            pqxx::result updateUserDBData = transaction.exec_prepared("update_user", uniqueHash, std::to_string(userID));

            transaction.commit(); // Commit the transaction

            clientData.storeClientData(clientDataStruct);  // Store clientData in the ClientData class


            return true;
        } else {
            // Authentication failed, return false
            transaction.abort(); // Rollback the transaction (optional)
            return false;
        }
    } catch (const std::exception& e) {
        // Handle database connection or query errors
        std::cerr << "Database error: " << e.what() << std::endl;
        // You might want to send an error response back to the client or log the error
        return false;
    }
}