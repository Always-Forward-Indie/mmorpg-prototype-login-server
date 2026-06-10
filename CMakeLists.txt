cmake_minimum_required(VERSION 3.10)

project(MMOLoginServer)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build type is set via -DCMAKE_BUILD_TYPE=Debug|Release (defaults to none if omitted)

# Define your project's source files
set(SOURCE_FILES
    src/main.cpp
    src/login_server/LoginServer.cpp
    src/network/NetworkManager.cpp
    src/services/Authenticator.cpp
    src/services/CharacterManager.cpp
    src/services/AccountManager.cpp
    src/data/ClientData.cpp
    src/utils/ThreadPool.cpp
    src/utils/Database.cpp
    src/utils/DatabasePool.cpp
    src/utils/Config.cpp
    src/utils/JSONParser.cpp
    src/utils/Logger.cpp
    src/utils/TimestampUtils.cpp
    src/events/Event.cpp
    src/events/EventHandler.cpp
    src/events/EventQueue.cpp
    # ... other source files
)

# Define your project's header files
set(HEADER_FILES
    include/login_server/LoginServer.hpp
    include/network/NetworkManager.hpp
    include/services/Authenticator.hpp
    include/services/CharacterManager.hpp
    include/services/AccountManager.hpp
    include/data/ClientData.hpp
    include/data/DataStructs.hpp
    include/data/SpecialStructs.hpp
    include/utils/Database.hpp
    include/utils/ThreadPool.hpp
    include/utils/Config.hpp
    include/utils/JSONParser.hpp
    include/utils/TerminalColors.hpp
    include/utils/Logger.hpp
    include/utils/ResponseBuilder.hpp
    include/utils/TimestampUtils.hpp
    include/events/Event.hpp
    include/events/EventHandler.hpp
    include/events/EventQueue.hpp
    # ... other header files
)

# Include directories for your project's headers
include_directories(include)

# Ensure libpqxx is correctly detected
find_package(PkgConfig REQUIRED)
pkg_check_modules(libpqxx REQUIRED IMPORTED_TARGET libpqxx)

# spdlog
find_package(spdlog REQUIRED)

# OpenSSL (used for SHA-256 password hashing in AccountManager)
find_package(OpenSSL REQUIRED)

# Create the executable
add_executable(${PROJECT_NAME} ${SOURCE_FILES} ${HEADER_FILES})

target_link_libraries(${PROJECT_NAME} PkgConfig::libpqxx spdlog::spdlog_header_only OpenSSL::Crypto)
