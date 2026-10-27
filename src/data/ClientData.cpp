#include "data/ClientData.hpp"
#include <iostream>

void ClientData::storeClientData(const ClientDataStruct &clientData)
{
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.
    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    ClientDataStruct copy = clientData;
    copy.lastSeenMs = nowMs();
    // Never store a cleartext password in memory longer than needed.
    copy.password.clear();
    clientDataMap_[copy.clientId] = std::move(copy);
    //logger_.log("ClientDataStruct stored in ClientData class with hash = " + std::to_string(clientData.clientId), BLUE);
}

std::unordered_map<int, ClientDataStruct> ClientData::getClientsDataMap() const
{
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.
    return clientDataMap_;
}

//Update client data
void ClientData::updateClientData(const int& id, const std::string& field, const std::string& value) {
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.

    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    auto it = clientDataMap_.find(id);
    if (it != clientDataMap_.end()) {
        try {
            if(field == "characterId") {
                it->second.characterData.characterId = std::stoi(value);
            } else if(field == "characterLevel") {
                it->second.characterData.characterLevel = std::stoi(value);
            } else if(field == "characterName") {
                it->second.characterData.characterName = value;
            } else if(field == "characterClass") {
                it->second.characterData.characterClass = value;
            } else {
                return;
            }
            it->second.lastSeenMs = nowMs();
        } catch (const std::exception&) {
            // stoi failure: leave stored data untouched (previously threw out of the lock).
        }
    }
}

//Update client character data with argument CharacterDataStruct
void ClientData::updateClientData(const int& id, const CharacterDataStruct& characterData) {
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.
    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    auto it = clientDataMap_.find(id);
    if (it != clientDataMap_.end()) {
        it->second.characterData = characterData;
        it->second.lastSeenMs = nowMs();
    }
}

std::optional<ClientDataStruct> ClientData::getClientData(const int &id) const
{
    if (id == 0)
    {
        return std::nullopt;
    }
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    auto it = clientDataMap_.find(id); // Find the client data in the map
    if (it != clientDataMap_.end())
    {
        return it->second; // copy under lock — safe after unlock
    }
    return std::nullopt;
}

bool ClientData::safeEqual(const std::string& a, const std::string& b)
{
    if (a.size() != b.size())
        return false;
    volatile unsigned diff = 0;
    for (size_t i = 0; i < a.size(); ++i)
        diff |= static_cast<unsigned>(a[i] ^ b[i]);
    return diff == 0;
}

bool ClientData::validateSession(int id, const std::string& hash) const
{
    if (id == 0 || hash.empty())
        return false;
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    auto it = clientDataMap_.find(id);
    if (it == clientDataMap_.end())
        return false;
    if (it->second.hash.empty())
        return false;
    return safeEqual(it->second.hash, hash);
}

bool ClientData::touchSession(int id, long long now)
{
    if (id == 0)
        return false;
    if (now == 0)
        now = nowMs();
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    auto it = clientDataMap_.find(id);
    if (it == clientDataMap_.end())
        return false;
    it->second.lastSeenMs = now;
    return true;
}

// remove client data
bool ClientData::removeClientData(const int& id) {
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    auto it = clientDataMap_.find(id);
    if (it != clientDataMap_.end()) {
        clientDataMap_.erase(it);
        return true;
    }
    return false;
}

std::vector<int> ClientData::sweepExpiredSessions(long long nowMs, long long ttlMs)
{
    std::vector<int> removed;
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    for (auto it = clientDataMap_.begin(); it != clientDataMap_.end();)
    {
        // All stored entries are timestamped on write; age alone decides.
        if ((nowMs - it->second.lastSeenMs) > ttlMs)
        {
            removed.push_back(it->first);
            it = clientDataMap_.erase(it);
        }
        else
        {
            ++it;
        }
    }
    return removed;
}

size_t ClientData::size() const
{
    std::lock_guard<std::mutex> lock(clientDataMutex_);
    return clientDataMap_.size();
}
