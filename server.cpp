#include <iostream>
#include <string>
#include <thread>
#include <chrono>
#include <winsock2.h>

#pragma comment(lib, "ws2_32.lib")

using namespace std;

int main() {
    WSADATA wsaData;
    SOCKET serverSocket;
    SOCKADDR_IN serverAddr;

    // Initialize Winsock
    int result = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (result != 0) {
        cout << "WSAStartup failed with error: " << result << endl;
        return 1;
    }

    // Create a TCP socket
    serverSocket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (serverSocket == INVALID_SOCKET) {
        cout << "socket creation failed with error: " << WSAGetLastError() << endl;
        WSACleanup();
        return 1;
    }

    // Bind the socket to a local address and port
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(54000);

    result = bind(serverSocket, (SOCKADDR*)&serverAddr, sizeof(serverAddr));
    if (result == SOCKET_ERROR) {
        cout << "bind failed with error: " << WSAGetLastError() << endl;
        closesocket(serverSocket);
        WSACleanup();
        return 1;
    }

    // Listen for incoming connections
    result = listen(serverSocket, SOMAXCONN);
    if (result == SOCKET_ERROR) {
        cout << "listen failed with error: " << WSAGetLastError() << endl;
        closesocket(serverSocket);
        WSACleanup();
        return 1;
    }

    cout << "Server started successfully on port 54000" << endl;

    // Wait for incoming connections
    while (true) {
        SOCKET clientSocket;
        SOCKADDR_IN clientAddr;
        int addrLen = sizeof(clientAddr);

        // Accept a new client connection
        clientSocket = accept(serverSocket, (SOCKADDR*)&clientAddr, &addrLen);
        if (clientSocket == INVALID_SOCKET) {
            cout << "accept failed with error: " << WSAGetLastError() << endl;
            closesocket(serverSocket);
            WSACleanup();
            return 1;
        }

        // Handle the client connection in a new thread
        thread clientThread([](SOCKET socket) {
            while (true) {
                // Receive data from the client
                char buffer[1024];
                int result = recv(socket, buffer, sizeof(buffer), 0);
                if (result > 0) {
                    cout << "Received data from client: " << buffer << endl;

                    // Send a response back to the client
                    result = send(socket, "Hello from server", 18, 0);
                    if (result == SOCKET_ERROR) {
                        cout << "send failed with error: " << WSAGetLastError() << endl;
                    }
                } else if (result == 0) {
                    cout << "Client disconnected" << endl;
                    break;
                } else {
                    cout << "recv failed with error: " << WSAGetLastError() << endl;
                    break;
                }
            }
        }, clientSocket);


        clientThread.detach();
    }

    // Close the server socket and cleanup Winsock
    closesocket(serverSocket);
    WSACleanup();

    return 0;
}