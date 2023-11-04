#include "helpers/Database.hpp"
#include "helpers/Config.hpp"
#include <iostream>

Database::Database() {
    connect();
    prepareDefaultQueries();
}

void Database::connect() {
    try {
        Config config;
        auto configs = config.parseConfig("config.json");
        short port = std::get<0>(configs).port;
        std::string host = std::get<0>(configs).host;
        std::string databaseName = std::get<0>(configs).dbname;
        std::string user = std::get<0>(configs).user;
        std::string password = std::get<0>(configs).password;

        std::cout << "Connecting to database..." << std::endl;
        std::cout << "Database name: " << databaseName << std::endl;
        std::cout << "User: " << user << std::endl;
        std::cout << "Host: " << host << std::endl;
        std::cout << "Port: " << port << std::endl;

        connection_ = std::make_unique<pqxx::connection>(
            "dbname=" + databaseName + " user=" + user + " password=" + password + " hostaddr=" + host + " port=" + std::to_string(port));

        if (connection_->is_open()) {
            std::cout << "Database connection established" << std::endl;
        } else {
            std::cout << "Database connection failed" << std::endl;
            // Handle the connection failure (e.g., throw an exception or exit)
        }
    } catch (const std::exception& e) {
        std::cerr << "Error while connecting to the database: " << e.what() << std::endl;
        // Handle the exception (e.g., throw it or exit the application)
    }
}

void Database::prepareDefaultQueries() {
    if (connection_->is_open()) {
        connection_->prepare("search_user", "SELECT * FROM users WHERE login = $1 AND password = $2 LIMIT 1;");
        connection_->prepare("update_user", "UPDATE users SET session_key = $1 WHERE id = $2;");

        connection_->prepare("get_characters_list", "SELECT characters.id as character_id, characters.level as character_lvl, "
        "characters.name as character_name, character_class.name as character_class, race.name as race_name "
        "FROM characters "
        "JOIN character_class ON characters.class_id = character_class.id " 
        "JOIN race on characters.race_id = race.id "
        "WHERE characters.owner_id = $1;");
        connection_->prepare("select_character", "SELECT characters.id as character_id, characters.level as character_lvl, "
        "characters.name as character_name, character_class.name as character_class, race.name as race_name "
        "FROM characters "
        "JOIN character_class ON characters.class_id = character_class.id "
        "JOIN race on characters.race_id = race.id "
        "WHERE characters.owner_id = $1 AND characters.id = $2 LIMIT 1;");
        connection_->prepare("create_character", "INSERT INTO characters (owner_id, name, class_id, race_id) VALUES ($1, $2, $3, $4);");
    } else {
        std::cerr << "Cannot prepare queries: Database connection is not open." << std::endl;
        // Handle this situation (e.g., throw an exception or exit)
    }
}

pqxx::connection& Database::getConnection() {
    if (connection_->is_open()) {
        return *connection_;
    } else {
        throw std::runtime_error("Database connection is not open.");
    }
}