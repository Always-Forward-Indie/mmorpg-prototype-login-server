#pragma once

#include <cstdlib>
#include <string>
#include <tuple>

struct DatabaseConfig {
    std::string dbname;
    std::string user;
    std::string password;
    std::string host;
    short port;
};

struct LoginServerConfig {
    std::string host;
    short port;
    short max_clients;
    std::string minClientVersion = "0.1.0";
    std::string maxClientVersion = "0.1.0";
};

class Config {
public:
    std::tuple<DatabaseConfig, LoginServerConfig> parseConfig();
};
