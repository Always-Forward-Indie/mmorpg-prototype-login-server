// ClientData.hpp
#pragma once

#include <string>
#include <unordered_map>
#include "data/DataStructs.hpp"

class ClientData {
public:
    void storeClientData(const ClientDataStruct& clientData);
    void updateClientData(const int& id, const std::string& field, const std::string& value);
    void updateClientData(const int& id, const CharacterDataStruct& characterData);
    const ClientDataStruct* getClientData(const int& id) const;
    std::unordered_map<int, ClientDataStruct> getClientsDataMap() const;
    void removeClientData(const int& id);

private:
    std::unordered_map<int, ClientDataStruct> clientDataMap_;
    mutable std::mutex clientDataMutex_; // mutex for each significant data segment if needed
};
