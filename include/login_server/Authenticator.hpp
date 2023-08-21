// Authenticator.hpp
#pragma once

#include <string>
#include "login_server/ClientData.hpp" // Include the header file for ClientData

class Authenticator {
public:
    int authenticate(const std::string& login, const std::string& password, const std::string& hash, ClientData& clientData);

private:
    // Define your authentication logic here
};