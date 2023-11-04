// Authenticator.hpp
#pragma once

#include <string>
#include "login_server/ClientData.hpp" // Include the header file for ClientData
#include "helpers/Database.hpp" // Include the header file for Database

class Authenticator {
public:
    int authenticate(const std::string& login, const std::string& password, ClientData& clientData, Database& database);

private:
    // Define your authentication logic here
};