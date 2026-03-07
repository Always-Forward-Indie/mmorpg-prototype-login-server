#pragma once

#include <pqxx/pqxx>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <queue>
#include <vector>
#include <chrono>
#include <stdexcept>
#include "utils/Config.hpp"
#include "utils/Logger.hpp"

/// CRITICAL-6: Connection pool for login-server.
/// Prevents O(N) login latency from single-connection serialization at 2000+ concurrent logins.
/// Each acquire() returns a Guard holding one connection; releasing the Guard returns it to the pool.
class DatabasePool
{
public:
    /// RAII guard — holds a pooled connection; returns it on destruction.
    /// Non-copyable. Moveable so it can be returned from functions.
    class Guard
    {
    public:
        Guard(DatabasePool &pool, pqxx::connection *conn) : pool_(&pool), conn_(conn) {}
        ~Guard()
        {
            if (pool_ && conn_)
                pool_->release(conn_);
        }
        Guard(Guard &&o) noexcept : pool_(o.pool_), conn_(o.conn_) { o.conn_ = nullptr; }
        Guard(const Guard &) = delete;
        Guard &operator=(const Guard &) = delete;

        pqxx::connection &get() { return *conn_; }

    private:
        DatabasePool *pool_;
        pqxx::connection *conn_;
    };

    /// @param cfg     database config (host, port, dbname, user, password)
    /// @param logger  logger reference
    /// @param poolSize number of connections to open (default 5; tune based on PostgreSQL max_connections)
    DatabasePool(const DatabaseConfig &cfg, Logger &logger, int poolSize = 5);
    ~DatabasePool() = default;

    /// Acquire a connection. Blocks until one is available or timeout expires.
    /// Throws std::runtime_error on timeout.
    Guard acquire(std::chrono::milliseconds timeout = std::chrono::milliseconds(5000));

private:
    void release(pqxx::connection *conn);

    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
    std::vector<std::unique_ptr<pqxx::connection>> connections_; ///< owns all connections
    std::queue<pqxx::connection *> available_;                   ///< pointers into connections_
    std::mutex mutex_;
    std::condition_variable cv_;
};
