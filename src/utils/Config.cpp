#include "utils/Config.hpp"
#include <filesystem> // Include the filesystem header
namespace fs = std::filesystem; // Alias for the filesystem namespace

    std::tuple<DatabaseConfig, LoginServerConfig> Config::parseConfig(const std::string& configFile) {
    DatabaseConfig DBConfig;
    LoginServerConfig LSConfig;

    // Get the current working directory
    fs::path currentPath = fs::current_path();

    // Construct the full path to the config.json file relative to the current directory
    fs::path configPath = currentPath / configFile;

    // Convert the full path to a string
    std::string configPathStr = configPath.string();

    try {
        // Open the JSON configuration file
        std::ifstream ifs(configPathStr);
        if (!ifs.is_open()) {
            throw std::runtime_error("Failed to open configuration file: " + configPathStr);
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