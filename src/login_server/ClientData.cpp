#include "login_server/ClientData.hpp"

void ClientData::storeClientData(const ClientDataStruct& clientData) {
    // Assuming that clientDataMap_ is an unordered_map with the key as the hash and the value as ClientDataStruct.
    clientDataMap_[clientData.hash] = clientData;
}

const ClientDataStruct* ClientData::getClientData(const std::string& hash) const {
    auto it = clientDataMap_.find(hash);
    if (it != clientDataMap_.end()) {
        return &it->second;
    }
    return nullptr;
}