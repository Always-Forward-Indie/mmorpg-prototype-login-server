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
    const ClientDataStruct* getClientData(const int& id) const;

private:
    std::unordered_map<int, ClientDataStruct> clientDataMap_;
};
