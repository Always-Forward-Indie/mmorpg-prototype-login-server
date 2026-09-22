// ClientData.hpp
#pragma once

#include <chrono>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>
#include "data/DataStructs.hpp"

class ClientData {
public:
    void storeClientData(const ClientDataStruct& clientData);
    void updateClientData(const int& id, const std::string& field, const std::string& value);
    void updateClientData(const int& id, const CharacterDataStruct& characterData);

    /// Thread-safe copy. Returns nullopt for id==0 or unknown id.
    /// Previously returned a raw pointer into the map under a released lock
    /// (use-after-free / data race when store/remove ran concurrently).
    std::optional<ClientDataStruct> getClientData(const int& id) const;

    /// Validate an incoming session without mutating state.
    /// Rejects id==0, empty hash, unknown id, or hash mismatch (constant-time compare).
    bool validateSession(int id, const std::string& hash) const;

    /// Refresh last-seen timestamp for an existing session (heartbeat / activity).
    /// Returns false when the id is unknown.
    bool touchSession(int id, long long nowMs = 0);

    std::unordered_map<int, ClientDataStruct> getClientsDataMap() const;

    /// Thread-safe removal. Returns true when an entry was erased.
    /// Previously had no lock at all (race with store/get).
    bool removeClientData(const int& id);

    /// Remove entries idle longer than ttlMs. Returns removed ids for logging/metrics.
    std::vector<int> sweepExpiredSessions(long long nowMs, long long ttlMs);

    size_t size() const;

    static long long nowMs() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
                   std::chrono::steady_clock::now().time_since_epoch())
            .count();
    }

private:
    static bool safeEqual(const std::string& a, const std::string& b);

    std::unordered_map<int, ClientDataStruct> clientDataMap_;
    mutable std::mutex clientDataMutex_; // mutex for each significant data segment if needed
};
