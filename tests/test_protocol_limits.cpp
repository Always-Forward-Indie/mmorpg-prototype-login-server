// Unit tests for wire-protocol framing limits (Phase 0).
// Mirrors proto/mmo_proto.py MAX_MESSAGE_BYTES = 8KB.
#include "utils/ProtocolLimits.hpp"

#include <gtest/gtest.h>

TEST(ProtocolLimits, MaxMessageIs8K) {
    EXPECT_EQ(protocol::kMaxMessageBytes, 8u * 1024u);
    EXPECT_GT(protocol::kMaxAccumulatedBytes, protocol::kMaxMessageBytes);
    EXPECT_EQ(protocol::kReadChunkBytes, 8u * 1024u);
}

TEST(ProtocolLimits, ErrorCodesStable) {
    // Contract pins: bots and docs/protocol reference these strings.
    EXPECT_STREQ(protocol::kErrOversize, "ERR_OVERSIZE");
    EXPECT_STREQ(protocol::kErrMalformed, "ERR_MALFORMED");
    EXPECT_STREQ(protocol::kProtocolVersion, "1.0");
}
