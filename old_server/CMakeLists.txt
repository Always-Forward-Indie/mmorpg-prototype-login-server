cmake_minimum_required(VERSION 3.8)

project(CServer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(PostgreSQL_DIR "C:/Program Files/PostgreSQL/15")
find_package(PostgreSQL 15.0 REQUIRED)

set(CMAKE_PREFIX_PATH "H:/Game Dev/Projects/c_libs/libpqxx")
find_package(libpqxx 7.8.0 REQUIRED NO_CMAKE_PACKAGE_REGISTRY)

include_directories("H:/Game Dev/Projects/c_libs/libpqxx/include")
include_directories("H:/Game Dev/Projects/c_libs/nlohmann/json/include")

add_executable(CServer main.cpp)

target_link_libraries(CServer PRIVATE libpqxx::pqxx)