#include "utils/Database.hpp"
#include "utils/Config.hpp"
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
            short port = std::get<0>(configs).port;
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
    conn.prepare("search_user",
                 "SELECT id, login, password, role, is_active, "
                 "locked_until, failed_login_attempts "
                 "FROM users "
                 "WHERE login = $1 "
                 "AND is_active = true "
                 "AND (locked_until IS NULL OR locked_until < now()) "
                 "LIMIT 1;");
    conn.prepare("increment_failed_logins",
                 "UPDATE users "
                 "SET failed_login_attempts = failed_login_attempts + 1, "
                 "locked_until = CASE WHEN failed_login_attempts + 1 >= 5 "
                 "  THEN now() + interval '15 minutes' ELSE locked_until END "
                 "WHERE login = $1;");
    conn.prepare("reset_failed_logins",
                 "UPDATE users "
                 "SET failed_login_attempts = 0, locked_until = NULL, last_login = now(), last_login_ip = $2::inet "
                 "WHERE id = $1;");
    conn.prepare("create_user_session",
                 "INSERT INTO user_sessions (user_id, token_hash, created_at, expires_at) "
                 "VALUES ($1, $2, now(), now() + interval '30 days') "
                 "ON CONFLICT (token_hash) DO NOTHING;");
    ;

    conn.prepare("get_characters_list",
                 "SELECT c.id AS character_id, c.level AS character_lvl, "
                 "c.name AS character_name, cc.name AS character_class, r.name AS race_name, "
                 "c.experience_points, c.account_slot, cg.name AS gender_name, "
                 "COALESCE(ccs.current_health, 1) AS current_health, "
                 "COALESCE(ccs.current_mana, 1) AS current_mana "
                 "FROM characters c "
                 "JOIN character_class cc ON c.class_id = cc.id "
                 "JOIN race r ON c.race_id = r.id "
                 "LEFT JOIN character_genders cg ON cg.id = c.gender "
                 "LEFT JOIN character_current_state ccs ON ccs.character_id = c.id "
                 "WHERE c.owner_id = $1 AND c.deleted_at IS NULL "
                 "ORDER BY c.account_slot;");
    conn.prepare("select_character",
                 "SELECT c.id AS character_id, c.level AS character_lvl, "
                 "c.name AS character_name, cc.name AS character_class, r.name AS race_name, "
                 "c.experience_points, c.account_slot "
                 "FROM characters c "
                 "JOIN character_class cc ON c.class_id = cc.id "
                 "JOIN race r ON c.race_id = r.id "
                 "WHERE c.owner_id = $1 AND c.id = $2 AND c.deleted_at IS NULL "
                 "LIMIT 1;");
    // create_character — inserts base record; resolves class/race/gender by name.
    // Params: $1=owner_id(int), $2=character_name, $3=class_name, $4=race_name, $5=gender_name
    conn.prepare("create_character",
                 "INSERT INTO characters (owner_id, name, class_id, race_id, gender, account_slot) "
                 "SELECT $1::int, $2, cc.id, r.id, cg.id, "
                 "  COALESCE((SELECT MAX(account_slot) + 1 FROM characters WHERE owner_id = $1::int AND deleted_at IS NULL), 1) "
                 "FROM character_class cc "
                 "JOIN race r ON r.name = $4 "
                 "JOIN character_genders cg ON cg.name = $5 "
                 "WHERE cc.name = $3 "
                 "RETURNING id;");
    // init_character_state — called after create_character to set up health/mana state row
    conn.prepare("init_character_state",
                 "INSERT INTO character_current_state (character_id, current_health, current_mana) "
                 "VALUES ($1, 1, 1) "
                 "ON CONFLICT (character_id) DO NOTHING;");
    // init_character_position — creates default position row (0,0,0 zone=1 village)
    conn.prepare("init_character_position",
                 "INSERT INTO character_position (character_id, x, y, z, zone_id) "
                 "VALUES ($1, 0, 0, 200, 1) "
                 "ON CONFLICT DO NOTHING;");
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
        return pqxx::result();
    }
}
