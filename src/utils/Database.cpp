#include "utils/Database.hpp"
#include "utils/Config.hpp"
#include <iostream>

Database::Database(std::tuple<DatabaseConfig, LoginServerConfig>& configs, Logger& logger) 
: 
logger_(logger)
{
    connect(configs);
    prepareDefaultQueries();
}

void Database::connect(std::tuple<DatabaseConfig, LoginServerConfig>& configs)
{
    try
    {
        short port = std::get<0>(configs).port;
        std::string host = std::get<0>(configs).host;
        std::string databaseName = std::get<0>(configs).dbname;
        std::string user = std::get<0>(configs).user;
        std::string password = std::get<0>(configs).password;

        logger_.log("Connecting to database...", YELLOW);
        logger_.log("Database name: " + databaseName, BLUE);
        //logger_.log("User: " + user, BLUE);
        logger_.log("Host: " + host, BLUE);
        logger_.log("Port: " + std::to_string(port), BLUE);

        connection_ = std::make_unique<pqxx::connection>(
            "dbname=" + databaseName + " user=" + user + " password=" + password + " hostaddr=" + host + " port=" + std::to_string(port));

        if (connection_->is_open())
        {
            logger_.log("Database connection established!", GREEN);
        }
        else
        {
            logger_.logError("Database connection failed!");
        }
    }
    catch (const std::exception &e)
    {
        handleDatabaseError(e);
    }
}

void Database::prepareDefaultQueries() {
    if (connection_->is_open()) {
        connection_->prepare("search_user", "SELECT * FROM users WHERE login = $1 AND password = $2 LIMIT 1;");
        connection_->prepare("update_user", "UPDATE users SET session_key = $1 WHERE id = $2;");

        connection_->prepare("get_characters_list", "SELECT characters.id as character_id, characters.level as character_lvl, "
        "characters.name as character_name, character_class.name as character_class, race.name as race_name "
        "FROM characters "
        "JOIN character_class ON characters.class_id = character_class.id " 
        "JOIN race on characters.race_id = race.id "
        "WHERE characters.owner_id = $1;");
        connection_->prepare("select_character", "SELECT characters.id as character_id, characters.level as character_lvl, "
        "characters.name as character_name, character_class.name as character_class, race.name as race_name "
        "FROM characters "
        "JOIN character_class ON characters.class_id = character_class.id "
        "JOIN race on characters.race_id = race.id "
        "WHERE characters.owner_id = $1 AND characters.id = $2 LIMIT 1;");
        connection_->prepare("create_character", "INSERT INTO characters (owner_id, name, class_id, race_id) VALUES ($1, $2, $3, $4);");
    } else {
        logger_.logError("Cannot prepare queries: Database connection is not open.");
    }
}

pqxx::connection &Database::getConnection()
{
    if (connection_->is_open())
    {
        return *connection_;
    }
    else
    {
        throw std::runtime_error("Database connection is not open.");
    }
}

// Function to handle database errors
void Database::handleDatabaseError(const std::exception &e)
{
    // Handle database connection or query errors
    logger_.logError("Database error: " + std::string(e.what()));
}

// Function to execute a query with a transaction
using ParamType = std::variant<int, float, double, std::string>; // Define a type of data alias for the parameter type
pqxx::result Database::executeQueryWithTransaction(
    pqxx::work &transaction,
    const std::string &preparedQueryName,
    const std::vector<ParamType> &parameters)
{
 try
    {
        // Create a params object to hold the parameters
        pqxx::params pq_params;

        //pqxx::internal::dynamic_params pq_params;

        // Loop through the parameters and add them to the pqxx::params object
        for (const auto &param : parameters)
        {
            std::visit([&](const auto &value) {
                pq_params.append(value);
            }, param);
        }

        // Execute the prepared query and assign the result to a pqxx::result object
        pqxx::result result = transaction.exec_prepared(preparedQueryName, parameters);
        // Return the result
        return result;
    }
    catch (const std::exception &e)
    {
        transaction.abort(); // Rollback the transaction
        handleDatabaseError(e); // Handle database connection or query errors
        return pqxx::result(); // Return an empty result
    }
}