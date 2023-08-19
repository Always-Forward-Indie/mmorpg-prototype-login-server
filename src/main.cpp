#include "login_server/LoginServer.hpp"
//#include "game_server/GameServer.hpp"

int main() {
    boost::asio::io_context io_context;
    short port = 8080;  // Choose your port number

    LoginServer loginServer(io_context, port);

    io_context.run();  // Start the event loop

    return 0;
}