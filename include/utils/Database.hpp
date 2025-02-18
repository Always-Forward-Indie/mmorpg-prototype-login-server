#ifndef DATABASE_HPP
#define DATABASE_HPP
 
#include <pqxx/pqxx>
#include <memory>
#include <variant>
#include "utils/Config.hpp"
#include "utils/Logger.hpp"

class Database {
public:
    // Constructor
    Database(std::tuple<DatabaseConfig, LoginServerConfig>& configs, Logger& logger);

    // Establish a database connection
    void connect(std::tuple<DatabaseConfig, LoginServerConfig>& configs);

    // Prepare default queries
    void prepareDefaultQueries();

    // Get a reference to the database connection
    pqxx::connection& getConnection();
    // Handle database connection or query errors
    void handleDatabaseError(const std::exception &e);
    // Execute a query with a transaction
    pqxx::result executeQueryWithTransaction(
    pqxx::work &transaction,
    const std::string &preparedQueryName,
    const std::vector<std::variant<int, float, double, std::string>> &parameters);

private:
    // Database connection
    std::unique_ptr<pqxx::connection> connection_;
    // Logger
    Logger& logger_;
};

#endif // DATABASE_HPP
