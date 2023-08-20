cmake_minimum_required(VERSION 3.10)

project(MMOServerPrototype)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)

# Define your project's source files
set(SOURCE_FILES
    src/main.cpp
    src/login_server/LoginServer.cpp
    src/login_server/Authenticator.cpp
    src/login_server/ClientData.cpp
    src/game_server/GameServer.cpp
    src/helpers/Database.cpp
    src/helpers/Config.cpp
    # ... other source files
)

# Define your project's header files
set(HEADER_FILES
    include/login_server/LoginServer.hpp
    include/login_server/Authenticator.hpp
    include/login_server/ClientData.hpp
    include/game_server/GameServer.hpp
    include/helpers/Database.hpp
    include/helpers/Config.hpp

    # ... other header files
)

# Include directories for your project's headers
include_directories(include)

# Create the executable
add_executable(${PROJECT_NAME} ${SOURCE_FILES} ${HEADER_FILES})
target_link_libraries(${PROJECT_NAME} pqxx)
target_link_libraries(${PROJECT_NAME} pq)