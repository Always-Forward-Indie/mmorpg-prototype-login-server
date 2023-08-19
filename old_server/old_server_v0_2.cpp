#include <winsock2.h>
#include <iostream>
#include <thread>
#include <chrono>
#include <mutex>
#include <iostream>
#include <string>
#include <ws2tcpip.h>
#include <sstream>
#include <vector>
#include <algorithm>
#include <pqxx/pqxx>

#pragma comment(lib, "ws2_32.lib")

using namespace std;

class Actor
{
public:
    Actor(SOCKET socket, int id, std::vector<int> &clients) : m_socket(socket), m_id(id), m_clients(clients)
    {
        m_thread = thread([this]()
                          {
                              while (true)
                              {
                                  // Receive data from the client
                                  char buffer[1024];
                                  int result = recv(m_socket, buffer, sizeof(buffer), 0);
                                  if (result == SOCKET_ERROR)
                                  {
                                      cout << "recv failed with error: " << WSAGetLastError() << endl;
                                      break;
                                  }
                                  if (result > 0)
                                  {
                                      // check for null terminator
                                      if (buffer[result - 1] == '\0')
                                      {
                                          buffer[result - 1] = '\0'; // terminate the string at the null character
                                      }
                                      else
                                      {
                                          // if there is no null terminator, add one
                                          buffer[result] = '\0';
                                      }
                                      std::cout << "Received data from client " << m_id << ": " << buffer << std::endl;

                                      // Handle client request to get the connected clients' IDs
                                      if (strstr(buffer, "get_connected_clients") != NULL)
                                      {
                                          handle_get_clients_request(m_socket, m_clients);
                                          continue; // Go back to receiving data from the client
                                      }

                                      // Echo the data back to the client
                                      int dataLength = strlen(buffer) + 1; // +1 to include null terminator
                                      int header = htonl(dataLength);
                                      result = send(m_socket, reinterpret_cast<const char *>(&header), sizeof(header), 0);
                                      if (result == SOCKET_ERROR)
                                      {
                                          cout << "send failed with error: " << WSAGetLastError() << endl;
                                          break;
                                      }
                                      result = send(m_socket, buffer, dataLength, 0);
                                      if (result == SOCKET_ERROR)
                                      {
                                          cout << "send failed with error: " << WSAGetLastError() << endl;
                                          break;
                                      }
                                      else
                                      {
                                         cout << "send data to client back " << endl;
                                      }
                                  }
                                  else
                                  {
                                      // Find the index of the client ID in the vector
                                      auto it = std::find(m_clients.begin(), m_clients.end(), m_id);

                                      // If the client ID is in the vector, erase it
                                      if (it != m_clients.end())
                                      {
                                          m_clients.erase(it);
                                      }

                                        std::lock_guard<std::mutex> lock(m_mutex); // Lock the mutex
                                      cout << "Client " << m_id << " disconnected" << endl;

                                      break;
                                  }
                              }

                              // Close the client socket
                              closesocket(m_socket);
                          });
    }

    ~Actor()
    {
        m_thread.join();
    }

    void handle_get_clients_request(SOCKET socket, const std::vector<int> &clients)
    {
        // Create a JSON object with the list of client IDs
        std::stringstream ss;
        ss << "{ \"clients\": [";
        for (const auto &clientId : clients)
        {
            ss << clientId << ",";
        }
        ss.seekp(-1, std::ios_base::end); // Remove the last comma
        ss << "], \"action\": \"get_connected_clients\" }";
        std::string json_str = ss.str();

        // Append null character to end of string
        json_str += '\0';

        // Send the list of client IDs back to the client
        int result = send(socket, json_str.c_str(), json_str.length(), 0);

        if (result == SOCKET_ERROR)
        {
            std::cerr << "Failed to send client list to client: " << WSAGetLastError() << std::endl;
        }
        else
        {
            std::cout << "Sent client list to client" << std::endl;
        }
    }

private:
    SOCKET m_socket;
    int m_id;
    std::vector<int> &m_clients;
    std::thread m_thread;
    std::mutex m_mutex;
};

int main()
{
    WSADATA wsaData;
    SOCKET serverSocket;
    SOCKADDR_IN serverAddr;
    std::vector<int> clients;

    const char *conn_string = "host=localhost user=root password=root dbname=mmo_prototype";

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
        clients.push_back(clientId);

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
        if (result == SOCKET_ERROR)
        {
            std::cerr << "Failed to send client ID to client: " << WSAGetLastError() << std::endl;
        }
        else
        {
            std::cout << "Sent client ID to client: " << clientIdStr << std::endl;
        }

        // Create a new actor to handle the client connection
        Actor *actor = new Actor(clientSocket, clientId, clients);
    }

    // Close the server socket
    closesocket(serverSocket);

    // Cleanup Winsock
    WSACleanup();

    return 0;
}