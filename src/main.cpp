#include "helpers/Config.hpp"
#include <iostream>
#include "login_server/LoginServer.hpp"
//#include "game_server/GameServer.hpp"

int main() {
    boost::asio::io_context io_context;
    Config config;
    auto configs = config.parseConfig("config.json");
    short port = std::get<1>(configs).port;  // Get port number from config.json
    std::string ip = std::get<1>(configs).host; // Get IP from config.json

    LoginServer loginServer(io_context, ip, port);
    //LoginServer loginServer(io_context, port);

    io_context.run();  // Start the event loop

    return 0;
}