#include "login_server/LoginServer.hpp"
#include <iostream>
#include <nlohmann/json.hpp>

LoginServer::LoginServer(boost::asio::io_context& io_context, short port)
    : io_context_(io_context),
      acceptor_(io_context),
      clientData_(),
      authenticator_() {
            boost::system::error_code ec;
            acceptor_.open(boost::asio::ip::tcp::v4(), ec);
            if (!ec) {
                acceptor_.set_option(boost::asio::ip::tcp::acceptor::reuse_address(true), ec);
                acceptor_.bind(boost::asio::ip::tcp::endpoint(boost::asio::ip::tcp::v4(), port), ec);
                acceptor_.listen(boost::asio::socket_base::max_listen_connections, ec);
            }

            if (ec) {
                std::cerr << "Error during server initialization: " << ec.message() << std::endl;
                return;
            }

            startAccept();

            // Print IP address and port when the server starts
            boost::asio::ip::tcp::endpoint endpoint = acceptor_.local_endpoint();
            std::cout << "Server started on IP: " << endpoint.address() << ", Port: " << endpoint.port() << std::endl;
}

void LoginServer::startAccept() {
    auto clientSocket = std::make_shared<boost::asio::ip::tcp::socket>(io_context_);
    acceptor_.async_accept(*clientSocket, [this, clientSocket](const boost::system::error_code& error) {
        if (!error) {
            // Get the client's remote endpoint (IP address and port)
            boost::asio::ip::tcp::endpoint remoteEndpoint = clientSocket->remote_endpoint();
            std::string clientIP = remoteEndpoint.address().to_string();

            // Print the client's IP address
            std::cout << "New client with IP: " << clientIP << " connected!" << std::endl;

            // Start reading data from the client
            startReadingFromClient(clientSocket);
        }

        // Continue accepting new connections even if there's an error
        startAccept();
    });
}

void LoginServer::handleClientData(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::array<char, max_length>& dataBuffer, size_t bytes_transferred) {
    try {
        nlohmann::json jsonData = nlohmann::json::parse(dataBuffer.data(), dataBuffer.data() + bytes_transferred);

        // Extract hash, login, type and password fields from the jsonData
        std::string type = jsonData["type"];
        std::string hash = jsonData["hash"];
        std::string login = jsonData["login"];
        std::string password = jsonData["password"];

        // Authenticate the client
        bool isAuthenticate = authenticator_.authenticate(login, password, hash, clientData_);  

        if (isAuthenticate) {
            // Authentication successful, send a success response back to the client
            std::cerr << "Authentication success for user: " << login << std::endl;
            // Create a response message
            std::string responseData = generateResponseMessage("success", "Authentication successful");
            // Send the response to the client
            sendResponse(clientSocket, responseData);
        } else {
            // Authentication failed for the client
            std::cerr << "Authentication failed for user: " << login << std::endl;
            // Create a response message
            std::string responseData = generateResponseMessage("error", "Authentication failed");
            // Send the response to the client
            sendResponse(clientSocket, responseData);
        }
    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "JSON parsing error: " << e.what() << std::endl;
        // Handle the error (e.g., close the socket)
    }
}

void LoginServer::sendResponse(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket, const std::string& responseString) {
    boost::asio::async_write(*clientSocket, boost::asio::buffer(responseString),
                             [this, clientSocket](const boost::system::error_code& error, size_t bytes_transferred) {
                                 if (!error) {
                                     // Response sent successfully, now start listening for the client's next message
                                     startReadingFromClient(clientSocket);
                                 } else {
                                     std::cerr << "Error during async_write: " << error.message() << std::endl;
                                     // Handle the error (e.g., close the socket)
                                 }
                             });
}

void LoginServer::startReadingFromClient(std::shared_ptr<boost::asio::ip::tcp::socket> clientSocket) {
    auto dataBuffer = std::make_shared<std::array<char, max_length>>();
    clientSocket->async_read_some(boost::asio::buffer(*dataBuffer),
        [this, clientSocket, dataBuffer](const boost::system::error_code& error, size_t bytes_transferred) {
            if (!error) {
                // Data has been read successfully, handle it
                handleClientData(clientSocket, *dataBuffer, bytes_transferred);

                // Continue reading from the client
                startReadingFromClient(clientSocket);
            } else if (error == boost::asio::error::eof) {
                // The client has closed the connection
                std::cerr << "Client disconnected gracefully." << std::endl;

                // You can perform any cleanup or logging here if needed

                // Close the client socket
                clientSocket->close();
            } else if (error == boost::asio::error::operation_aborted) {
                // The read operation was canceled, likely due to the client disconnecting
                std::cerr << "Read operation canceled (client disconnected)." << std::endl;

                // You can perform any cleanup or logging here if needed

                // Close the client socket
                clientSocket->close();
            } else {
                // Handle other errors
                std::cerr << "Error during async_read_some: " << error.message() << std::endl;

                // You can also close the socket in case of other errors if needed
                clientSocket->close();
            }
        });
}

std::string LoginServer::generateResponseMessage(const std::string& status, const std::string& message) {
    nlohmann::json response;

    response["status"] = status;
    response["message"] = message;
    std::string responseString = response.dump();

    return responseString;
}