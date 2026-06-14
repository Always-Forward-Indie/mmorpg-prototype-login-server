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
};

class Config {
public:
    std::tuple<DatabaseConfig, LoginServerConfig> parseConfig();
};
