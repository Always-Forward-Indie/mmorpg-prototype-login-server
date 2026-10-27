// S17a: VersionStats — pure version-attempt distribution, no sockets/DB.
#include "utils/VersionStats.hpp"

#include <gtest/gtest.h>

TEST(LoginVersionStats, EmptySnapshotIsEmpty)
{
    VersionStats vs;
    EXPECT_EQ(vs.snapshot(), "");
    EXPECT_EQ(vs.total(), 0u);
}

TEST(LoginVersionStats, CountsAcceptedAndRejectedAlike)
{
    VersionStats vs;
    vs.record("0.2.0");
    vs.record("0.1.2");
    vs.record("0.2.0");
    EXPECT_EQ(vs.total(), 3u);
    const std::string snap = vs.snapshot();
    EXPECT_NE(snap.find("0.2.0=2"), std::string::npos);
    EXPECT_NE(snap.find("0.1.2=1"), std::string::npos);
    EXPECT_NE(snap.find("(n=3)"), std::string::npos);
}

TEST(LoginVersionStats, GarbageCountedNotDropped)
{
    VersionStats vs;
    vs.record("{not-a-version");
    vs.record("");
    EXPECT_EQ(vs.total(), 2u);
    const std::string snap = vs.snapshot();
    EXPECT_NE(snap.find("{not-a-version=1"), std::string::npos);
    EXPECT_NE(snap.find("(empty)=1"), std::string::npos);
}

TEST(LoginVersionStats, DistinctCapBucketsOverflow)
{
    VersionStats vs;
    for (size_t i = 0; i < VersionStats::kMaxDistinct + 10; ++i)
        vs.record("v" + std::to_string(i));
    EXPECT_EQ(vs.total(), VersionStats::kMaxDistinct + 10);
    const std::string snap = vs.snapshot();
    // 10 overflowed into the guard bucket, nothing lost from the total.
    EXPECT_NE(snap.find("_other=10"), std::string::npos);
    EXPECT_NE(snap.find("(n=74)"), std::string::npos);
}

TEST(LoginVersionStats, LongKeysTruncated)
{
    VersionStats vs;
    vs.record(std::string(100, '9'));
    const std::string snap = vs.snapshot();
    EXPECT_EQ(snap.find(std::string(100, '9')), std::string::npos);
    EXPECT_NE(snap.find(std::string(32, '9') + "=1"), std::string::npos);
}
