# Login-server unit tests (gtest). Run inside the dev container:
#   ctest --test-dir /usr/src/app/build --output-on-failure
find_package(GTest QUIET)
if(GTest_FOUND)
    add_executable(unit_tests
        test_account_manager.cpp
        test_event_queue.cpp
        test_db_pool.cpp
        test_threadpool.cpp
        test_config.cpp
        test_protocol_limits.cpp
        test_jsonparser_position.cpp
        test_client_data.cpp
        test_query_registry.cpp
        ../src/services/AccountManager.cpp
        ../src/data/ClientData.cpp
        ../src/events/Event.cpp
        ../src/events/EventQueue.cpp
        ../src/utils/Logger.cpp
        ../src/utils/ThreadPool.cpp
        ../src/utils/Config.cpp
        ../src/utils/QueryRegistry.cpp
        ../src/utils/JSONParser.cpp
        ../src/utils/TimestampUtils.cpp
    )
    target_link_libraries(unit_tests PRIVATE
        GTest::gtest_main
        PkgConfig::libpqxx
        spdlog::spdlog_header_only
        OpenSSL::Crypto
    )
    add_test(NAME unit COMMAND unit_tests)
else()
    message(WARNING "GTest not found - unit tests skipped (install libgtest-dev, build & install)")
endif()
