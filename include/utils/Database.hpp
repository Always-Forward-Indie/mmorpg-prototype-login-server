#ifndef DATABASE_HPP
#define DATABASE_HPP

#include <pqxx/pqxx>
#include <memory>
#include <mutex>
#include <variant>
#include "utils/Config.hpp"
#include "utils/Logger.hpp"

class Database
{
public:
    // Constructor
    Database(std::tuple<DatabaseConfig, LoginServerConfig> &configs, Logger &logger);

    // Establish a database connection
    void connect(std::tuple<DatabaseConfig, LoginServerConfig> &configs);

    // Prepare default queries
    void prepareDefaultQueries();

    /// Static helper: prepare all named queries on an arbitrary open pqxx::connection.
    /// Called by DatabasePool for each pooled connection.
    static void prepareQueriesOn(pqxx::connection &conn);

    /// CRITICAL-10/6 fix: RAII wrapper that holds the DB mutex for the lifetime of a transaction.
    /// Prevents concurrent pqxx::work on the single connection (pqxx is not thread-safe).
    /// TODO: Replace with DatabasePool when prepareDefaultQueries is refactored for multi-connection.
    struct ScopedConnection
    {
        std::unique_lock<std::mutex> lock;
        pqxx::connection &conn;
        ScopedConnection(std::mutex &m, pqxx::connection &c) : lock(m), conn(c) {}
        /// Construct with an already-owned lock (HIGH-10 reconnect path)
        ScopedConnection(std::unique_lock<std::mutex> l, pqxx::connection &c) : lock(std::move(l)), conn(c) {}
        ScopedConnection(ScopedConnection &&) = default;
        pqxx::connection &get() { return conn; }
    };
    ScopedConnection getConnectionLocked();

    /// Legacy accessor — single-threaded use only.
    pqxx::connection &getConnection();

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
    /// HIGH-10: stored connection string for reconnect
    std::string connectionString_;
    /// CRITICAL-10: serialises concurrent pqxx::work transactions on the single connection
    mutable std::mutex dbMutex_;
    // Logger
    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
};

#endif // DATABASE_HPP
