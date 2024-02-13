// Authenticator.hpp
#pragma once

#include <string>
#include "data/ClientData.hpp" // Include the header file for ClientData
#include "utils/Database.hpp" // Include the header file for Database

class Authenticator {
public:
    int authenticate(Database& database, ClientData& clientData, const std::string& login, const std::string& password);
};