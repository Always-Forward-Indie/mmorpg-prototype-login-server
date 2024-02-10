#include "login_server/Authenticator.hpp"
#include "helpers/Database.hpp"
#include <boost/uuid/random_generator.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_io.hpp>
#include <string>
#include <pqxx/pqxx>
#include <iostream>

// Add these using declarations for convenience
using namespace pqxx;
using namespace std;

int Authenticator::authenticate(Database& database, ClientData& clientData, const std::string& login, const std::string& password) {
    try {
        // Create a transactional object. It automatically starts a transaction.
        pqxx::work transaction(database.getConnection());
        // Check if the provided login and password match a record in the database
        pqxx::result getUserDBData = transaction.exec_prepared("search_user", login, password);

        if (!getUserDBData.empty()) {
            int userID = 0;

            // Loop through the result set and process the data
            for (pqxx::result::size_type i = 0; i < getUserDBData.size(); ++i) {
                userID = getUserDBData[i][0].as<int>(); // Access the second column (index 1)
            }

            transaction.commit(); // Commit the transaction

            // Generate a unique hash for the client
            boost::uuids::uuid uuid = boost::uuids::random_generator()();
            std::string uniqueHash = boost::uuids::to_string(uuid);

            // Create a ClientDataStruct with the login, password, and unique hash
            ClientDataStruct clientDataStruct;
            clientDataStruct.clientId = userID;
            clientDataStruct.login = login;
            clientDataStruct.hash = uniqueHash;

            pqxx::result updateUserDBData = transaction.exec_prepared("update_user", uniqueHash, std::to_string(userID));

            transaction.commit(); // Commit the transaction

            clientData.storeClientData(clientDataStruct);  // Store clientData in the ClientData class

            return userID;
        } else {
            // Authentication failed, return false
            transaction.abort(); // Rollback the transaction (optional)
            return 0;
        }
    } catch (const std::exception& e) {
        // Handle database connection or query errors
        std::cerr << "Database error: " << e.what() << std::endl;
        // You might want to send an error response back to the client or log the error
        return 0;
    }
}