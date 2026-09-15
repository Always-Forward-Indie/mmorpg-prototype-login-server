#pragma once
#include <array>
#include <deque>
#include <memory>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <mutex>
#include <boost/asio.hpp>
#include <nlohmann/json.hpp>
#include "data/DataStructs.hpp"
#include "utils/Logger.hpp"
#include "utils/Config.hpp"
#include "utils/JSONParser.hpp"
#include "events/EventQueue.hpp"

class NetworkManager
{
public:
    NetworkManager(EventQueue &eventQueue, std::tuple<DatabaseConfig, LoginServerConfig> &configs, Logger &logger);
    ~NetworkManager();
    void startAccept();
    void startIOEventLoop();
    void sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &responseString);
    /// Reclaim idle per-socket write queues (owner-expired only). Called
    /// periodically (LoginServer cleanup branch).
    void gcWriteQueues();
    std::string generateResponseMessage(const std::string &status, const nlohmann::json &message);
    std::string generateResponseMessage(const std::string &status, const nlohmann::json &message, const TimestampStruct &timestamps);

private:
    static constexpr size_t max_length = 1024; // Define the appropriate value
    void handleAccept(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const boost::system::error_code &error);
    void startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket);
    void handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    void processMessage(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &message);
    bool checkClientVersion(const std::string &clientVersion, const std::string &eventType,
                            std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket);

    // Per-socket serialized write queue. The io_context runs on N threads,
    // so concurrent async_write() calls on the same socket are UB in Asio —
    // all writes go through the socket's strand (mirrors chunk-server-new).
    struct SocketWriteQueue
    {
        boost::asio::strand<boost::asio::io_context::executor_type> strand;
        std::deque<std::shared_ptr<const std::string>> pending;
        bool writing{false};
        // Owner identity: a raw socket* key alone is unsafe (free+realloc may
        // reuse the address); a stale queue must never swallow a new socket.
        std::weak_ptr<boost::asio::ip::tcp::socket> owner;

        explicit SocketWriteQueue(boost::asio::io_context &ioc)
            : strand(boost::asio::make_strand(ioc))
        {
        }
    };

    std::shared_ptr<SocketWriteQueue> getOrCreateWriteQueue(
        const std::shared_ptr<boost::asio::ip::tcp::socket> &socket);
    void removeWriteQueue(boost::asio::ip::tcp::socket *key,
        const std::shared_ptr<boost::asio::ip::tcp::socket> &expectedOwner);
    void enqueueWrite(std::shared_ptr<boost::asio::ip::tcp::socket> socket,
        std::shared_ptr<const std::string> data);
    void doNextWrite(std::shared_ptr<boost::asio::ip::tcp::socket> socket,
        std::shared_ptr<SocketWriteQueue> queue);

    std::unordered_map<boost::asio::ip::tcp::socket *, std::shared_ptr<SocketWriteQueue>> writeQueues_;
    std::mutex writeQueuesMutex_;

    boost::asio::io_context io_context_;
    boost::asio::ip::tcp::acceptor acceptor_;
    std::thread networkManagerThread_;
    std::vector<std::thread> threadPool_;
    std::tuple<DatabaseConfig, LoginServerConfig> &configs_;
    EventQueue &eventQueue_;
    Logger &logger_;
    std::shared_ptr<spdlog::logger> log_;
    JSONParser jsonParser_;
    std::mutex socketBufferMutex_;
    std::unordered_map<boost::asio::ip::tcp::socket *, std::string> socketBuffers_;
    std::mutex activeSocketsMutex_;
    std::unordered_set<boost::asio::ip::tcp::socket *> activeSockets_;
};