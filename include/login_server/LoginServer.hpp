#pragma once

#include <boost/asio.hpp>
#include <array>
#include <string>
#include <nlohmann/json.hpp>
#include "Authenticator.hpp"
#include "CharacterManager.hpp"
#include "helpers/Database.hpp"

class LoginServer
{
public:
    LoginServer(boost::asio::io_context &io_context, const std::string &customIP, short customPort, short maxClients);

private:
    static constexpr size_t max_length = 1024; // Define the appropriate value

    void startAccept();
    void handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::array<char, max_length> &dataBuffer, size_t bytes_transferred);
    void startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket);
    void sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &responseString);
    std::string generateResponseMessage(const std::string &status, const nlohmann::json &message, const int &id);

    void authenticateClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string &login, const std::string &password);
    void createCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const std::string &characterName, const std::string &characterClass, const std::string &hash);
    void selectCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const std::string &characterName, const std::string &hash);
    void getCharactersList(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const std::string &hash);
    void selectCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const int &characterID, const std::string &hash);
    void deleteCharacter(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const int &characterID, const std::string &hash);

    void logoutClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const int &clientID, const std::string &hash);

    boost::asio::io_context &io_context_;
    boost::asio::ip::tcp::acceptor acceptor_;

    ClientData clientData_;
    Authenticator authenticator_;
    CharacterManager characterManager_;
    Database database_;
};
