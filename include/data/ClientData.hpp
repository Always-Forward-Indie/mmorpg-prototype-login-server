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

private:
    std::unordered_map<int, ClientDataStruct> clientDataMap_;
};
