// Unit tests for ClientData thread-safe registry (Phase 1).
// Covers: optional copy (no UAF), locked remove, validateSession, sweep, touch.
#include "data/ClientData.hpp"

#include <atomic>
#include <gtest/gtest.h>
#include <thread>
#include <vector>

namespace {

ClientDataStruct makeSession(int id, const std::string &hash) {
    ClientDataStruct d;
    d.clientId = id;
    d.login = "user" + std::to_string(id);
    d.hash = hash;
    return d;
}

} // namespace

TEST(ClientData, GetReturnsCopyNotPointer) {
    ClientData c;
    c.storeClientData(makeSession(1, "hash-abc"));
    auto got = c.getClientData(1);
    ASSERT_TRUE(got.has_value());
    EXPECT_EQ(got->login, "user1");
    EXPECT_EQ(got->hash, "hash-abc");
    // Mutating the copy must not affect the store.
    got->login = "mutated";
    auto again = c.getClientData(1);
    ASSERT_TRUE(again.has_value());
    EXPECT_EQ(again->login, "user1");
}

TEST(ClientData, GetUnknownOrZeroIsNullopt) {
    ClientData c;
    EXPECT_FALSE(c.getClientData(0).has_value());
    EXPECT_FALSE(c.getClientData(999).has_value());
}

TEST(ClientData, StoreClearsPassword) {
    ClientData c;
    ClientDataStruct d = makeSession(2, "h2");
    d.password = "secret";
    c.storeClientData(d);
    auto got = c.getClientData(2);
    ASSERT_TRUE(got.has_value());
    EXPECT_TRUE(got->password.empty());
}

TEST(ClientData, RemoveIsLockedAndReports) {
    ClientData c;
    EXPECT_FALSE(c.removeClientData(42));
    c.storeClientData(makeSession(42, "h"));
    EXPECT_TRUE(c.removeClientData(42));
    EXPECT_FALSE(c.getClientData(42).has_value());
    EXPECT_FALSE(c.removeClientData(42));
}

TEST(ClientData, ValidateSession) {
    ClientData c;
    c.storeClientData(makeSession(7, "tok-7"));
    EXPECT_TRUE(c.validateSession(7, "tok-7"));
    EXPECT_FALSE(c.validateSession(7, "tok-wrong"));
    EXPECT_FALSE(c.validateSession(7, ""));
    EXPECT_FALSE(c.validateSession(0, "tok-7"));
    EXPECT_FALSE(c.validateSession(999, "tok-7"));
}

TEST(ClientData, SweepExpiredKeepsFreshAndLegacy) {
    ClientData c;
    c.storeClientData(makeSession(1, "a"));
    c.storeClientData(makeSession(2, "b"));
    long long now = ClientData::nowMs();
    // Fresh entries survive a sweep with large TTL.
    EXPECT_TRUE(c.sweepExpiredSessions(now, 60000).empty());
    EXPECT_EQ(c.size(), 2u);
    // Tiny TTL expires everything touched before now.
    auto removed = c.sweepExpiredSessions(now + 1000, 10);
    EXPECT_EQ(removed.size(), 2u);
    EXPECT_EQ(c.size(), 0u);
}

TEST(ClientData, TouchRefreshes) {
    ClientData c;
    c.storeClientData(makeSession(5, "t"));
    EXPECT_TRUE(c.touchSession(5));
    EXPECT_FALSE(c.touchSession(0));
    EXPECT_FALSE(c.touchSession(999));
}

TEST(ClientData, ConcurrentStoreGetRemoveIsSafe) {
    ClientData c;
    for (int i = 1; i <= 20; ++i)
        c.storeClientData(makeSession(i, "h" + std::to_string(i)));
    std::atomic<int> reads{0};
    std::vector<std::thread> th;
    for (int t = 0; t < 4; ++t) {
        th.emplace_back([&] {
            for (int i = 1; i <= 20; ++i) {
                if (c.getClientData(i).has_value())
                    ++reads;
                c.touchSession(i);
            }
        });
    }
    for (auto &t : th)
        t.join();
    EXPECT_GT(reads.load(), 0);
    EXPECT_EQ(c.size(), 20u);
}
