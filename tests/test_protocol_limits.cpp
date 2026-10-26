// Unit tests for wire-protocol framing limits.
// v1 line cap (8KB) is kept for the fixed-size read buffer; v2 frames go
// up to kMaxFrameBytes (4MB). Mirrors proto/mmo_proto.py MAX_FRAME_BYTES.
#include "utils/ProtocolLimits.hpp"

#include <gtest/gtest.h>

TEST(ProtocolLimits, MaxMessageIs8K) {
    EXPECT_EQ(protocol::kMaxMessageBytes, 8u * 1024u);
    EXPECT_GT(protocol::kMaxAccumulatedBytes, protocol::kMaxMessageBytes);
    EXPECT_EQ(protocol::kReadChunkBytes, 8u * 1024u);
}

TEST(ProtocolLimits, V2FrameBudget) {
    EXPECT_EQ(protocol::kMaxFrameBytes, 4u * 1024u * 1024u);
    EXPECT_GT(protocol::kMaxAccumulatedBytesV2, protocol::kMaxFrameBytes);
}

TEST(ProtocolLimits, ErrorCodesStable) {
    // Contract pins: bots and docs/protocol reference these strings.
    EXPECT_STREQ(protocol::kErrOversize, "ERR_OVERSIZE");
    EXPECT_STREQ(protocol::kErrMalformed, "ERR_MALFORMED");
    EXPECT_STREQ(protocol::kProtocolVersion, "1.0");
}
