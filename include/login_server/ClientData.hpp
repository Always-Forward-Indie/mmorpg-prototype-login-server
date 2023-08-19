// ClientData.hpp
#pragma once

#include <string>
#include <unordered_map>

struct ClientDataStruct
{
    int clientId;
    std::string login;
    std::string hash;
};


class ClientData {
public:
    void storeClientData(const ClientDataStruct& clientData);
    const ClientDataStruct* getClientData(const std::string& hash) const;

private:
    std::unordered_map<std::string, ClientDataStruct> clientDataMap_;
};
