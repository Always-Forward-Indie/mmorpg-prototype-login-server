#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <sstream>

#pragma comment(lib, "ws2_32.lib")

using namespace std;

class Actor
{
public:
    Actor(SOCKET socket, int id) : m_socket(socket), m_id(id)
    {
        m_thread = thread([this]()
                          {
            while (true) {
                // Receive data from the client
                char buffer[1024];
                int result = recv(m_socket, buffer, sizeof(buffer), 0);
                if (result > 0) {
                    // check for null terminator
                    if (buffer[result-1] == '\0') {
                        buffer[result-1] = '\0'; // terminate the string at the null character
                    } else {
                        // if there is no null terminator, add one
                        buffer[result] = '\0';
                    }
                    cout << "Received data from client " << m_id << ": " << buffer << endl;

                    // Echo the data back to the client
                    int dataLength = strlen(buffer) + 1; // +1 to include null terminator
                    int header = htonl(dataLength);
                    result = send(m_socket, buffer, dataLength, 0);
                    if (result == SOCKET_ERROR) {
                        cout << "send failed with error: " << WSAGetLastError() << endl;
                    }
                } else if (result == 0) {
                    cout << "Client " << m_id << " disconnected" << endl;
                    break;
                } else {
                    cout << "recv failed with error: " << WSAGetLastError() << endl;
                    break;
                }
            }

            

            // Close the client socket
            closesocket(m_socket); });
    }

    ~Actor()
    {
        m_thread.join();
    }

private:
    SOCKET m_socket;
    int m_id;
    thread m_thread;
};

int main()
{
    WSADATA wsaData;
    SOCKET serverSocket;
    SOCKADDR_IN serverAddr;

    // Initialize Winsock
    int result = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (result != 0)
    {
        cout << "WSAStartup failed with error: " << result << endl;
        return 1;
    }

    // Create a TCP socket
    serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (serverSocket == INVALID_SOCKET)
    {
        cout << "socket creation failed with error: " << WSAGetLastError() << endl;
        WSACleanup();
        return 1;
    }

    // Bind the socket to a local address and port
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(54000);

    result = bind(serverSocket, (SOCKADDR *)&serverAddr, sizeof(serverAddr));
    if (result == SOCKET_ERROR)
    {
        cout << "bind failed with error: " << WSAGetLastError() << endl;
        closesocket(serverSocket);
        WSACleanup();
        return 1;
    }

// Listen for incoming connections
result = listen(serverSocket, SOMAXCONN);
if (result == SOCKET_ERROR)
{
    cout << "listen failed with error: " << WSAGetLastError() << endl;
    closesocket(serverSocket);
    WSACleanup();
    return 1;
}

cout << "Server started successfully on port 54000" << endl;

// Wait for incoming connections
while (true)
{
    SOCKET clientSocket;
    SOCKADDR_IN clientAddr;
    int addrLen = sizeof(clientAddr);

    // Accept a new client connection
    clientSocket = accept(serverSocket, (SOCKADDR *)&clientAddr, &addrLen);
    if (clientSocket == INVALID_SOCKET)
    {
        cout << "accept failed with error: " << WSAGetLastError() << endl;
        closesocket(serverSocket);
        WSACleanup();
        return 1;
    }

    // Generate random ID for the client
    int clientId = rand() % 1000;

    // Create a JSON object with the client ID
    std::stringstream ss;
    ss << "{ \"client_id\": " << clientId << ", \"action\": \"connected\" }";
    std::string json_str_id = ss.str();

    // Convert ID to string
    string clientIdStr = to_string(clientId);
    // Append null character to end of string
    json_str_id += '\0';

    cout << "New client connected with ID " << clientId << endl;

    // Send the ID back to the client
    result = send(clientSocket, json_str_id.c_str(), json_str_id.length(), 0);
    if (result == SOCKET_ERROR) {
        std::cerr << "Failed to send client ID to client: " << WSAGetLastError() << std::endl;
    } else {
        std::cout << "Sent client ID to client: " << clientIdStr << std::endl;
    }

    // Create a new actor to handle the client connection
    Actor *actor = new Actor(clientSocket, clientId);
}

// Close the server socket
closesocket(serverSocket);

// Cleanup Winsock
WSACleanup();

return 0;
}