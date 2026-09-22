// Unit tests for layered Config (defaults < config.json < ENV) + validation.
// Pure logic, no DB, no sockets. Covers Phase 0 Config rework.
#include "utils/Config.hpp"

#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <gtest/gtest.h>
#include <unistd.h>

namespace {

void clearEnv() {
    unsetenv("DB_NAME");
    unsetenv("DB_USER");
    unsetenv("DB_PASSWORD");
    unsetenv("DB_HOST");
    unsetenv("DB_PORT");
    unsetenv("SERVER_HOST");
    unsetenv("SERVER_PORT");
    unsetenv("SERVER_MAX_CLIENTS");
    unsetenv("MIN_CLIENT_VERSION");
    unsetenv("MAX_CLIENT_VERSION");
}

struct EnvGuard {
    EnvGuard() { clearEnv(); }
    ~EnvGuard() { clearEnv(); }
};

std::string writeTempJson(const std::string &body) {
    char tmpl[] = "/tmp/mmo_login_cfg_XXXXXX";
    int fd = mkstemp(tmpl);
    EXPECT_NE(fd, -1);
    {
        std::ofstream f(tmpl);
        f << body;
    }
    close(fd);
    return std::string(tmpl);
}

} // namespace

TEST(Config, DefaultsWhenNoFileNoEnv) {
    EnvGuard g;
    Config c;
    auto [db, ls] = c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json");
    EXPECT_EQ(db.dbname, "mmo_prototype");
    EXPECT_EQ(db.host, "127.0.0.1");
    EXPECT_EQ(db.port, 5432);
    EXPECT_EQ(ls.host, "0.0.0.0");
    EXPECT_EQ(ls.port, 27014);
    EXPECT_EQ(ls.max_clients, 3000);
}

TEST(Config, EnvOverridesDefaults) {
    EnvGuard g;
    setenv("DB_PORT", "5433", 1);
    setenv("SERVER_PORT", "27015", 1);
    setenv("SERVER_MAX_CLIENTS", "100", 1);
    Config c;
    auto [db, ls] = c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json");
    EXPECT_EQ(db.port, 5433);
    EXPECT_EQ(ls.port, 27015);
    EXPECT_EQ(ls.max_clients, 100);
}

TEST(Config, InvalidPortThrowsWithVarName) {
    EnvGuard g;
    setenv("SERVER_PORT", "not_a_number", 1);
    Config c;
    try {
        c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json");
        FAIL() << "expected runtime_error";
    } catch (const std::runtime_error &e) {
        EXPECT_NE(std::string(e.what()).find("SERVER_PORT"), std::string::npos);
    }
}

TEST(Config, PortOutOfRangeThrows) {
    EnvGuard g;
    setenv("SERVER_PORT", "99999", 1);
    Config c;
    EXPECT_THROW(c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json"), std::runtime_error);
    // Boundary: 0 is invalid, 65535 is valid.
    setenv("SERVER_PORT", "0", 1);
    EXPECT_THROW(c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json"), std::runtime_error);
    setenv("SERVER_PORT", "65535", 1);
    auto [db, ls] = c.parseConfig("/tmp/mmo_cfg_definitely_missing_12345.json");
    EXPECT_EQ(ls.port, 65535);
}

TEST(Config, JsonFileProvidesDefaultsEnvWins) {
    EnvGuard g;
    std::string path = writeTempJson(R"({"server_host":"10.0.0.5","server_port":27100})");
    Config c;
    {
        auto [db, ls] = c.parseConfig(path);
        EXPECT_EQ(ls.host, "10.0.0.5");
        EXPECT_EQ(ls.port, 27100);
    }
    setenv("SERVER_PORT", "27200", 1);
    {
        auto [db, ls] = c.parseConfig(path);
        EXPECT_EQ(ls.host, "10.0.0.5");
        EXPECT_EQ(ls.port, 27200);
    }
    std::remove(path.c_str());
}

TEST(Config, MalformedJsonThrows) {
    EnvGuard g;
    std::string path = writeTempJson("{not json");
    Config c;
    EXPECT_THROW(c.parseConfig(path), std::runtime_error);
    std::remove(path.c_str());
}
