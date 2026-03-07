// Authenticator.hpp
#pragma once

#include <pqxx/pqxx>
#include <string>
#include "data/ClientData.hpp"

class Authenticator
{
public:
    int authenticate(pqxx::connection &conn, ClientData &clientData, const std::string &login, const std::string &password);
};