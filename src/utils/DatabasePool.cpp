#include "utils/DatabasePool.hpp"
#include "utils/Database.hpp"
#include <sstream>
#include <stdexcept>
#include <spdlog/logger.h>

DatabasePool::DatabasePool(const DatabaseConfig &cfg, Logger &logger, int poolSize)
    : logger_(logger)
{
    log_ = logger.getSystem("db");
    const std::string connStr =
        "dbname=" + cfg.dbname +
        " user=" + cfg.user +
        " password=" + cfg.password +
        " host=" + cfg.host +
        " port=" + std::to_string(cfg.port);

    logger_.log("[DatabasePool] Opening " + std::to_string(poolSize) + " connections to " +
                cfg.host + ":" + std::to_string(cfg.port) + "/" + cfg.dbname);

    connections_.reserve(poolSize);
    for (int i = 0; i < poolSize; ++i)
    {
        try
        {
            auto conn = std::make_unique<pqxx::connection>(connStr);
            if (!conn->is_open())
                throw std::runtime_error("Connection " + std::to_string(i) + " failed to open");
            Database::prepareQueriesOn(*conn);
            available_.push(conn.get());
            connections_.push_back(std::move(conn));
        }
        catch (const std::exception &e)
        {
            logger_.logError("[DatabasePool] Failed to open connection " +
                             std::to_string(i) + ": " + e.what());
            throw;
        }
    }

    log_->info("[DatabasePool] All " + std::to_string(poolSize) + " connections ready.");
}

DatabasePool::Guard
DatabasePool::acquire(std::chrono::milliseconds timeout)
{
    std::unique_lock<std::mutex> lock(mutex_);

    if (!cv_.wait_for(lock, timeout, [this]
                      { return !available_.empty(); }))
    {
        throw std::runtime_error("[DatabasePool] acquire() timed out: pool exhausted after " +
                                 std::to_string(timeout.count()) + "ms. Consider increasing pool size.");
    }

    pqxx::connection *conn = available_.front();
    available_.pop();
    return Guard(*this, conn);
}

void DatabasePool::release(pqxx::connection *conn)
{
    {
        std::lock_guard<std::mutex> lock(mutex_);
        available_.push(conn);
    }
    cv_.notify_one();
}
