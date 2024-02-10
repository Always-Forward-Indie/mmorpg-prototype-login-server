// Authenticator.hpp
#pragma once

#include <string>
#include "login_server/ClientData.hpp" // Include the header file for ClientData
#include "helpers/Database.hpp" // Include the header file for Database

class Authenticator {
public:
    int authenticate(Database& database, ClientData& clientData, const std::string& login, const std::string& password);
};