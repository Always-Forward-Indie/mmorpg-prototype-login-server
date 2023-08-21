#include "helpers/Config.hpp"

    std::tuple<DatabaseConfig, LoginServerConfig> Config::parseConfig(const std::string& configFile) {
    DatabaseConfig DBConfig;
    LoginServerConfig LSConfig;

    try {
        // Open the JSON configuration file
        std::ifstream ifs(configFile);
        if (!ifs.is_open()) {
            throw std::runtime_error("Failed to open configuration file: " + configFile);
        }

        // Parse the JSON data
        nlohmann::json root;
        ifs >> root;

        // Extract database connection details
        DBConfig.dbname = root["database"]["dbname"].get<std::string>();
        DBConfig.user = root["database"]["user"].get<std::string>();
        DBConfig.password = root["database"]["password"].get<std::string>();
        DBConfig.host = root["database"]["host"].get<std::string>();
        DBConfig.port = root["database"]["port"].get<short>();

        // Extract login server connection details
        LSConfig.host = root["login_server"]["host"].get<std::string>();
        LSConfig.port = root["login_server"]["port"].get<short>();
        LSConfig.max_clients = root["login_server"]["max_clients"].get<short>();

    } catch (const std::exception& e) {
        // Handle any errors that occur during parsing or reading the configuration file
        std::cerr << "Error while parsing configuration: " << e.what() << std::endl;
        // You may want to throw or handle the error differently based on your application's needs
    }

    // Construct and return the tuple with the extracted values
    return std::make_tuple(DBConfig, LSConfig);
}