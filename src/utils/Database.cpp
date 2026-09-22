#include "utils/Database.hpp"
#include "utils/Config.hpp"
#include "utils/QueryRegistry.hpp"
#include <iostream>
#include <thread>
#include <chrono>
#include <spdlog/logger.h>

Database::Database(std::tuple<DatabaseConfig, LoginServerConfig> &configs, Logger &logger)
    : logger_(logger)
{
    log_ = logger.getSystem("db");
    connect(configs);
    prepareDefaultQueries();
}

void Database::connect(std::tuple<DatabaseConfig, LoginServerConfig> &configs)
{
    int retries = 5;
    while (retries > 0)
    {
        try
        {
            std::uint16_t port = std::get<0>(configs).port;
            std::string host = std::get<0>(configs).host;
            std::string databaseName = std::get<0>(configs).dbname;
            std::string user = std::get<0>(configs).user;
            std::string password = std::get<0>(configs).password;

            log_->info("Connecting to database...");
            log_->debug("Database name: " + databaseName);
            // log_->debug("User: " + user);
            log_->debug("Host: " + host);
            log_->debug("Port: " + std::to_string(port));

            connectionString_ = "dbname=" + databaseName + " user=" + user + " password=" + password + " host=" + host + " port=" + std::to_string(port);
            connection_ = std::make_unique<pqxx::connection>(connectionString_);

            if (connection_->is_open())
            {
                log_->info("Database connection established!");
                break;
            }
            else
            {
                log_->error("Database connection failed!");
            }
        }
        catch (const std::exception &e)
        {
            handleDatabaseError(e);
        }

        retries--;
        if (retries > 0)
        {
            log_->info("Retrying in 5 seconds...");
            std::this_thread::sleep_for(std::chrono::seconds(5));
        }
        else
        {
            log_->error("Failed to connect to the database after multiple attempts.");
        }
    }
}

void Database::prepareDefaultQueries()
{
    if (connection_->is_open())
        prepareQueriesOn(*connection_);
    else
        log_->error("Cannot prepare queries: Database connection is not open.");
}

void Database::prepareQueriesOn(pqxx::connection &conn)
{
    // Search user by login — returns user row including hashed password for verification in app code.
    // Also checks is_active and lock status (locked_until).
    // Registration order is preserved (see QueryRegistry).
    for (const QueryDef *q = queryRegistryBegin(); q != queryRegistryEnd(); ++q)
        conn.prepare(std::string(q->name), std::string(q->sql));
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

Database::ScopedConnection Database::getConnectionLocked()
{
    std::unique_lock<std::mutex> lock(dbMutex_);
    // HIGH-10: reconnect if the connection was lost
    if (!connection_ || !connection_->is_open())
    {
        log_->info("Database connection lost — reconnecting...");
        try
        {
            connection_ = std::make_unique<pqxx::connection>(connectionString_);
            if (connection_->is_open())
            {
                log_->info("Database reconnected successfully.");
                prepareDefaultQueries();
            }
            else
            {
                throw std::runtime_error("Reconnect attempt failed: connection not open.");
            }
        }
        catch (const std::exception &e)
        {
            throw std::runtime_error("Database reconnect failed: " + std::string(e.what()));
        }
    }
    return ScopedConnection(std::move(lock), *connection_);
}

// Function to handle database errors
void Database::handleDatabaseError(const std::exception &e)
{
    // Handle database connection or query errors
    logger_.logError("Database error: " + std::string(e.what()));
}

// Function to execute a query with a transaction
// using ParamType = std::variant<int, float, double, std::string>; // Define a type of data alias for the parameter type
pqxx::result Database::executeQueryWithTransaction(
    pqxx::work &transaction,
    const std::string &preparedQueryName,
    const std::vector<std::variant<int, float, double, std::string>> &parameters)
{
    try
    {
        // Convert all parameters to strings
        std::vector<std::string> paramStrings;
        for (const auto &param : parameters)
        {
            paramStrings.push_back(std::visit([](const auto &value) -> std::string
                                              {
                if constexpr (std::is_same_v<std::decay_t<decltype(value)>, std::string>)
                    return value;
                else
                    return std::to_string(value); }, param));
        }

        // Convert to a vector of raw C-style strings (needed for exec_prepared)
        std::vector<const char *> cstrParams;
        for (auto &param : paramStrings)
        {
            cstrParams.push_back(param.c_str());
        }

        // Use the parameter pack expansion to pass all arguments dynamically
        pqxx::result result = transaction.exec_prepared(preparedQueryName, pqxx::prepare::make_dynamic_params(cstrParams.begin(), cstrParams.end()));

        return result;
    }
    catch (const std::exception &e)
    {
        transaction.abort(); // Rollback transaction
        handleDatabaseError(e);
        // Fail loud with query context: an empty pqxx::result is a valid
        // "no rows" answer and must never double as an error signal.
        // (No live callers today — all new code uses DatabasePool + exec_prepared
        // with explicit empty() checks — but the trap stays closed.)
        throw DatabaseError("executeQueryWithTransaction[" + preparedQueryName + "]: " + e.what());
    }
}
