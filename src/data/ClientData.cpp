#include "data/ClientData.hpp"
#include <iostream>

void ClientData::storeClientData(const ClientDataStruct &clientData)
{
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.
    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    clientDataMap_[clientData.clientId] = clientData;
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
        if(field == "characterId") {
            it->second.characterData.characterId = std::stoi(value);
        } else if(field == "characterLevel") {
            it->second.characterData.characterLevel = std::stoi(value);
        } else if(field == "characterName") {
            it->second.characterData.characterName = value;
        } else if(field == "characterClass") {
            it->second.characterData.characterClass = value;
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
    }
}

const ClientDataStruct *ClientData::getClientData(const int &id) const
{
    if (id == 0)
    {
        return nullptr;
    }
    std::lock_guard<std::mutex> lock(clientDataMutex_); // lock_guard is a mutex wrapper that provides a convenient RAII-style mechanism for owning a mutex for the duration of a scoped block.
    auto it = clientDataMap_.find(id); // Find the client data in the map
    if (it != clientDataMap_.end())
    {
        return &it->second;
    }
    return nullptr;
}

// remove client data
void ClientData::removeClientData(const int& id) {
    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    auto it = clientDataMap_.find(id);
    if (it != clientDataMap_.end()) {
        clientDataMap_.erase(it);
    }
}