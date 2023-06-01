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
#include <nlohmann/json.hpp>

#pragma comment(lib, "ws2_32.lib")

using namespace std;
using json = nlohmann::json;

class Actor
{
public:
    Actor(SOCKET socket, std::vector<int> &clients, pqxx::connection &db_connection) : act_socket(socket), act_clients(clients), act_db_connection(db_connection)
    {
        m_thread = thread([this]()
                          {
                                // Create a JSON object with action field set to connected
                                json response;
                                response["action"] = "connected";
                                std::string json_str = response.dump();
                                // Append null character to end of string
                                json_str += '\0';

                                cout << "New client connected" << endl;

                                // Send that client has connected to the server
                                int result = send(act_socket, json_str.c_str(), json_str.length(), 0);
                                if (result == SOCKET_ERROR)
                                {
                                    std::cerr << "Failed to send connected info to client: " << WSAGetLastError() << std::endl;
                                }
                                else
                                {
                                    std::cout << "Sent conected info to client." << std::endl;
                                }


                              while (true)
                              {
                                  // Receive data from the client
                                  char buffer[1024];
                                  int result = recv(act_socket, buffer, sizeof(buffer), 0);
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

                                        if (usr_id != 0){
                                                std::cout << "Received data from client " << usr_id << ": " << buffer << std::endl;
                                        } else {
                                                std::cout << "Received data from unauthorized client: " << buffer << std::endl;
                                        }
                                        

                                        // Handle client request to get the connected clients' IDs
                                        if (strstr(buffer, "get_connected_clients") != NULL)
                                        {
                                            handle_get_clients_request(act_socket, act_clients);
                                            continue; // Go back to receiving data from the client
                                        }

                                        // Handle client request to authorize using credentials provided by user
                                        if (strstr(buffer, "user_authorization_request") != NULL)
                                        {
                                            // Extract the JSON string from the buffer
                                            std::string json_str = buffer;
                                            json request;

                                            try {
                                                // Parse the JSON string from the client
                                                request = json::parse(json_str);
                                            } catch (const std::exception& ex) {
                                                // Handle parsing error
                                                std::cerr << "Error parsing JSON request: " << ex.what() << std::endl;
                                                continue; // Go back to receiving data from the client
                                            }

                                            // Extract the action, login, and password fields from the request object
                                            std::string action;
                                            std::string login;
                                            std::string password;

                                            try {
                                                action = request["action"].get<std::string>();
                                                login = request["login"].get<std::string>();
                                                password = request["password"].get<std::string>();
                                            } catch (const std::exception& ex) {
                                                // Handle missing or invalid fields
                                                std::cerr << "Error extracting fields from JSON request: " << ex.what() << std::endl;
                                                continue; // Go back to receiving data from the client
                                            }
                                            
                                            std::cout << "action: " << action << std::endl;
                                            std::cout << "login: " << login << std::endl;
                                            std::cout << "password: " << password << std::endl;

                                            //pass login and password to function that will check if they are correct in database
                                            handle_authorization_request(act_socket, login, password, act_db_connection);

                                            continue; // Go back to receiving data from the client
                                        }

                                        // Handle client request to get all characters from database for user   
                                        if (strstr(buffer, "get_user_characters_list") != NULL)
                                        {
                                            handle_get_characters_request(act_socket, get_user_id(), act_db_connection);
                                        }

                                        // Handle client request to get selected character from database for user
                                        if (strstr(buffer, "get_user_character") != NULL)
                                        {
                                            // Extract the JSON string from the buffer
                                            std::string json_str = buffer;
                                            json request;

                                            try {
                                                // Parse the JSON string from the client
                                                request = json::parse(json_str);
                                            } catch (const std::exception& ex) {
                                                // Handle parsing error
                                                std::cerr << "Error parsing JSON request: " << ex.what() << std::endl;
                                                continue; // Go back to receiving data from the client
                                            }

                                            // Extract the character_id field from the request object
                                            int character_id;

                                            try {
                                                character_id = request["character_id"].get<int>();
                                            } catch (const std::exception& ex) {
                                                // Handle missing or invalid fields
                                                std::cerr << "Error extracting fields from JSON request: " << ex.what() << std::endl;
                                                continue; // Go back to receiving data from the client
                                            }

                                            handle_get_selected_character_request(act_socket, get_user_id(), character_id, act_db_connection);
                                        }
                                        

                                        // Echo the data back to the client
                                        int dataLength = strlen(buffer) + 1; // +1 to include null terminator
                                        int header = htonl(dataLength);
                                        result = send(act_socket, reinterpret_cast<const char *>(&header), sizeof(header), 0);
                                        if (result == SOCKET_ERROR)
                                        {
                                            cout << "send failed with error: " << WSAGetLastError() << endl;
                                            break;
                                        }
                                        result = send(act_socket, buffer, dataLength, 0);
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
                                      auto it = std::find(act_clients.begin(), act_clients.end(), usr_id);

                                      // If the client ID is in the vector, erase it
                                      if (it != act_clients.end())
                                      {
                                          act_clients.erase(it);
                                      }

                                      std::lock_guard<std::mutex> lock(m_mutex); // Lock the mutex
                                      cout << "Client " << usr_id << " disconnected" << endl;

                                      break;
                                  }
                              }

                              // Close the client socket
                              closesocket(act_socket); });
    }

    ~Actor()
    {
        m_thread.join();
    }

    int get_user_id() const
    {
        return usr_id;
    }

    void set_user_id(int id)
    {
        usr_id = id;
    }

    std::string get_session_key() const
    {
        return session_key;
    }

    void set_session_key(std::string key)
    {
        session_key = key;
    }

    std::string generate_session_key(int length = 16)
    {
        std::string session_key;
        for (int i = 0; i < length; ++i)
        {
            // Generate random number between 0 and 255
            int rand_num = rand() % 256;
            // Convert the random number to a hex string
            std::stringstream stream;
            stream << std::hex << rand_num;
            std::string hex = stream.str();
            // If the hex string only contains one character, prepend a 0
            if (hex.length() == 1)
            {
                hex = "0" + hex;
            }
            session_key += hex;
        }
        return session_key;
    }

    void handle_get_clients_request(SOCKET socket, const std::vector<int> &clients)
    {
        // Create a JSON object with the list of client IDs
        json response;
        response["clients"] = clients;
        response["action"] = "get_connected_clients";
        std::string json_str = response.dump();

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

    void handle_authorization_request(SOCKET socket, std::string login, std::string password, pqxx::connection &db_connection)
    {
        try
        {

            // Check if login and password are correct in the database
            pqxx::nontransaction db_query(db_connection);
            pqxx::result db_result = db_query.exec(
                "SELECT id FROM users WHERE login = " + db_query.quote(login) +
                " AND password = " + db_query.quote(password));
            int id_user_from_database = 0;
            std::string session_key_new = "";

            // Start a transaction to perform the selection and update operations
            // pqxx::work db_update(db_connection);
            if (!db_result.empty())
            {
                // Get id from database
                id_user_from_database = db_result[0][0].as<int>();
                // Set user id for actor
                set_user_id(id_user_from_database);
                // Generate session key
                set_session_key(generate_session_key());
                session_key_new = get_session_key();

                // pqxx::nontransaction db_update(db_connection);

                // try {
                // Start a transaction to update session key in database
                // pqxx::work db_update(db_connection);
                db_query.exec("UPDATE users SET session_key = " + db_query.quote(session_key_new) + " WHERE id = " + db_query.quote(id_user_from_database));

                // Commit the transaction
                // db_update.commit();
                std::cout << "Updated User Session Key" << std::endl;
                //}
                // catch (const std::exception& ex) {
                // Handle transaction-related exception
                // db_update.abort();
                //  std::cerr << "Transaction exception occurred: " << ex.what() << std::endl;
                // Additional error handling logic can be added here
                //}
            }

            if (id_user_from_database != 0 && session_key_new != "")
            {
                // Add the new actor to the list of clients
                act_clients.push_back(get_user_id());
                // Create a JSON object with client ID, action and session key
                nlohmann::json response = {
                    {"action", "login_successful"},
                    {"message", "User authorization successful!"},
                    {"session_key", session_key_new},
                    {"user_id", id_user_from_database}};
                // Convert JSON object to string
                std::string json_str = response.dump();

                // Append null character to end of string
                json_str += '\0';

                // Send data back to the client
                int result = send(socket, json_str.c_str(), json_str.length(), 0);

                if (result == SOCKET_ERROR)
                {
                    std::cerr << "Failed to send login action status to client: " << WSAGetLastError() << std::endl;
                }
                else
                {
                    std::cout << "Sent login action status to client" << std::endl;
                }
            }
            else
            {
                // Create a JSON object with action login_failed
                nlohmann::json response = {
                    {"action", "login_failed"},
                    {"message", "User is not logged in!"}};
                std::string json_str = response.dump();

                // Append null character to end of string
                json_str += '\0';

                // Send the failed login action back to the client
                int result = send(socket, json_str.c_str(), json_str.length(), 0);

                if (result == SOCKET_ERROR)
                {
                    std::cerr << "Failed to send login_failed to client: " << WSAGetLastError() << std::endl;
                }
                else
                {
                    std::cout << "Sent login_failed to client" << std::endl;
                }
            }
        }
        catch (const pqxx::usage_error &ex)
        {
            // Handle the pqxx::usage_error exception
            std::cerr << "pqxx::usage_error occurred: " << ex.what() << std::endl;
            // Additional error handling logic can be added here
        }
        catch (const std::exception &ex)
        {
            // Handle other exceptions
            std::cerr << "Exception occurred: " << ex.what() << std::endl;
            // Additional error handling logic can be added here
        }
    }

    void handle_get_characters_request(SOCKET socket, int user_id, pqxx::connection &db_connection)
    {
        // Check if user is logged in
        if (user_id != 0 && get_session_key() != "")
        {
            // Get All characters from database for user
            pqxx::nontransaction db_query(act_db_connection);
            pqxx::result db_result = db_query.exec(
                "SELECT "
                "characters_attributes.character_id, characters.name, characters.level, "
                "race.name as race, character_class.name as class "
                "FROM characters "
                "JOIN characters_attributes on characters_attributes.character_id = characters.id  "
                "JOIN race on characters.race_id = race.id  "
                "JOIN character_class on characters.class_id = character_class.id  "
                "WHERE characters.owner_id = " +
                db_query.quote(user_id));
            std::vector<std::tuple<int, int, std::string, int, std::string, std::string>> characters_list;
            if (!db_result.empty())
            {
                for (auto row : db_result)
                {
                    int char_id = row[0].as<int>();
                    std::string char_name = row[1].as<std::string>();
                    int char_level = row[2].as<int>();
                    std::string char_race = row[3].as<std::string>();
                    std::string char_class = row[4].as<std::string>();
                    characters_list.push_back(std::make_tuple(char_id, user_id, char_name, char_level, char_race, char_class));
                }
            }
            // Create a JSON object with the list of characters data
            json response;
            response["action"] = "get_characters";
            response["characters_list"] = characters_list;
            response["user_id"] = user_id;
            std::string json_str = response.dump();

            // Append null character to end of string
            json_str += '\0';

            // Send the list of character back to the client
            int result = send(act_socket, json_str.c_str(), json_str.length(), 0);

            if (result == SOCKET_ERROR)
            {
                std::cerr << "Failed to send characters list to client: " << WSAGetLastError() << std::endl;
            }
            else
            {
                std::cout << "Sent characters list to client" << std::endl;
            }
        }
        else
        {
            // Create a JSON object with action get_user_characters_list_failed
            nlohmann::json response = {
                {"action", "get_user_characters_list_failed"},
                {"message", "User is not logged in!"}};
            std::string json_str = response.dump();

            // Append null character to end of string
            json_str += '\0';

            // Send action back to the client
            int result = send(socket, json_str.c_str(), json_str.length(), 0);

            if (result == SOCKET_ERROR)
            {
                std::cerr << "Failed to send get_user_characters_list_failed to client: " << WSAGetLastError() << std::endl;
            }
            else
            {
                std::cout << "Sent get_user_characters_list_failed to client" << std::endl;
            }
        }
    }

    void handle_get_selected_character_request(SOCKET socket, int user_id, int character_id, pqxx::connection &db_connection)
    {
        // Check if user is logged in
        if (user_id != 0 && get_session_key() != "" && character_id != 0)
        {
            // Get All characters from database for user
            pqxx::nontransaction db_query(act_db_connection);
            pqxx::result db_result = db_query.exec(
                "SELECT "
                "characters_attributes.character_id, characters.owner_id, characters.name, characters.level, "
                "race.name as race, character_class.name as class "
                "FROM characters "
                "JOIN characters_attributes on characters_attributes.character_id = characters.id  "
                "JOIN race on characters.race_id = race.id  "
                "JOIN character_class on characters.class_id = character_class.id  "
                "WHERE characters.owner_id = " +
                db_query.quote(user_id) + " AND characters.id = " + db_query.quote(character_id));

            // Create a JSON object with the character data
            if (!db_result.empty())
            {
                json response;
                response["action"] = "get_user_character";
                response["character_data"]["character_id"] = db_result[0][0].as<int>();
                response["character_data"]["owner_id"] = db_result[0][1].as<int>();
                response["character_data"]["name"] = db_result[0][2].as<std::string>();
                response["character_data"]["level"] = db_result[0][3].as<int>();
                response["character_data"]["race"] = db_result[0][4].as<std::string>();
                response["character_data"]["class"] = db_result[0][5].as<std::string>();
                response["user_id"] = user_id;
                std::string json_str = response.dump();

                // Append null character to end of string
                json_str += '\0';

                // Send the character data back to the client
                int result = send(act_socket, json_str.c_str(), json_str.length(), 0);

                if (result == SOCKET_ERROR)
                {
                    std::cerr << "Failed to send selected character data to client: " << WSAGetLastError() << std::endl;
                }
                else
                {
                    std::cout << "Sent selected character data to client" << std::endl;
                }
            }
            else
            {
                // Create a JSON object with action get_user_character_failed
                nlohmann::json response = {
                    {"action", "get_user_character_failed"},
                    {"message", "Invalid character ID!"}};
                std::string json_str = response.dump();

                // Append null character to end of string
                json_str += '\0';

                // Send action back to the client
                int result = send(socket, json_str.c_str(), json_str.length(), 0);

                if (result == SOCKET_ERROR)
                {
                    std::cerr << "Failed to send get_user_character_failed to client: " << WSAGetLastError() << std::endl;
                }
                else
                {
                    std::cout << "Sent get_user_character_failed to client" << std::endl;
                }
            }
        }
        else
        {
            // Create a JSON object with action get_user_character_failed
            nlohmann::json response = {
                {"action", "get_user_character_failed"},
                {"message", "User is not logged in!"}};
            std::string json_str = response.dump();

            // Append null character to end of string
            json_str += '\0';

            // Send action back to the client
            int result = send(socket, json_str.c_str(), json_str.length(), 0);

            if (result == SOCKET_ERROR)
            {
                std::cerr << "Failed to send get_user_character_failed to client: " << WSAGetLastError() << std::endl;
            }
            else
            {
                std::cout << "Sent get_user_character_failed to client" << std::endl;
            }
        }
    }

private:
    SOCKET act_socket;
    int usr_id = 0;
    int act_id = 0;
    std::vector<int> &act_clients;
    std::thread m_thread;
    std::mutex m_mutex;
    pqxx::connection &act_db_connection;
    std::string session_key;
};

int main()
{
    WSADATA wsaData;
    SOCKET serverSocket;
    SOCKADDR_IN serverAddr;
    std::vector<int> clients;

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

    result = ::bind(serverSocket, (SOCKADDR *)&serverAddr, sizeof(serverAddr));
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

    pqxx::connection DBconnection("dbname=mmo_prototype user=postgres password=root \
                          hostaddr=127.0.0.1 port=5434");
    if (!DBconnection.is_open())
    {
        cout << "Failed to connect to database" << endl;
        return 1;
    }
    else
    {
        cout << "Connected to database successfully" << endl;
    }

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

        // Create a new actor to handle the client connection
        Actor *actor = new Actor(clientSocket, clients, DBconnection);
    }

    // Close the database connection
    DBconnection.close();

    // Close the server socket
    closesocket(serverSocket);

    // Cleanup Winsock
    WSACleanup();

    return 0;
}