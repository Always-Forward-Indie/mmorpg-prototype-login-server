// Unit tests for JSONParser::parsePositionData operator-precedence fix.
// Before: `A && B && C && D_float || E_int` evaluated E even when "body"
// was absent -> exception -> whole packet lost in outer catch.
// After: parenthesised (float || int) with body guard.
#include "utils/JSONParser.hpp"
#include "utils/ProtocolLimits.hpp"

#include <array>
#include <cstring>
#include <gtest/gtest.h>
#include <string>

namespace {

std::pair<std::array<char, protocol::kMaxMessageBytes>, size_t> toBuf(const std::string &s) {
    std::array<char, protocol::kMaxMessageBytes> buf{};
    EXPECT_LT(s.size(), buf.size());
    std::memcpy(buf.data(), s.data(), s.size());
    return {buf, s.size()};
}

} // namespace

TEST(JsonParserPosition, MissingBodyReturnsDefaultNoThrow) {
    JSONParser p;
    auto [buf, n] = toBuf(R"({"header":{"eventType":"pingClient"}})");
    PositionStruct pos{};
    EXPECT_NO_THROW(pos = p.parsePositionData(buf, n));
    EXPECT_FLOAT_EQ(pos.positionX, 0.0f);
    EXPECT_FLOAT_EQ(pos.positionY, 0.0f);
    EXPECT_FLOAT_EQ(pos.positionZ, 0.0f);
}

TEST(JsonParserPosition, IntegerCoordsParsed) {
    JSONParser p;
    auto [buf, n] = toBuf(R"({"body":{"characterPosX":10,"characterPosY":-5,"characterPosZ":3}})");
    PositionStruct pos = p.parsePositionData(buf, n);
    EXPECT_FLOAT_EQ(pos.positionX, 10.0f);
    EXPECT_FLOAT_EQ(pos.positionY, -5.0f);
    EXPECT_FLOAT_EQ(pos.positionZ, 3.0f);
}

TEST(JsonParserPosition, FloatCoordsParsed) {
    JSONParser p;
    auto [buf, n] = toBuf(R"({"body":{"characterPosX":1.5,"characterPosY":2.25,"characterPosZ":-0.5}})");
    PositionStruct pos = p.parsePositionData(buf, n);
    EXPECT_FLOAT_EQ(pos.positionX, 1.5f);
    EXPECT_FLOAT_EQ(pos.positionY, 2.25f);
    EXPECT_FLOAT_EQ(pos.positionZ, -0.5f);
}
