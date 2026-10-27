// Unit tests for protocol v2 framing (S14, utils/WireFraming.hpp).
// Login-server twin of the chunk/game wire framing helpers: length-prefixed
// packing. Byte-level, no sockets/DB. (No sniff tests: login never had
// dual-read — a v1 line dies in the frame layer, see WireFraming.hpp.)
#include "utils/WireFraming.hpp"

#include <cstdint>
#include <gtest/gtest.h>

TEST(LoginFramingV2, PackRoundTrip)
{
    const std::string body = "{\"header\":{\"eventType\":\"x\"},\"body\":{}}";
    const std::string packed = wirev2::packFramedMessage(body);
    ASSERT_EQ(packed.size(), 4 + body.size());
    const uint8_t *p = reinterpret_cast<const uint8_t *>(packed.data());
    const std::uint32_t n = static_cast<std::uint32_t>(p[0]) |
                            (static_cast<std::uint32_t>(p[1]) << 8) |
                            (static_cast<std::uint32_t>(p[2]) << 16) |
                            (static_cast<std::uint32_t>(p[3]) << 24);
    EXPECT_EQ(n, body.size());
    EXPECT_EQ(packed.substr(4), body);
}