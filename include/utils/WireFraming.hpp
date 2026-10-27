#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

#include "utils/ProtocolLimits.hpp"

/// Protocol v2 wire framing, login-server twin (S14).
/// Mirrors chunk `wire::` framing helpers (separate repo, no shared
/// include): `[u32 LE length][UTF-8 JSON]`, 4MB cap. See chunk-server
/// docs/api/14-framing-v2-protocol.md for the full contract.
///
/// NOTE (cleanup): unlike game/chunk, login never had dual-read — the
/// sniff helper and FramingMode enum were removed. Login is v2-only
/// since S14d: a v1 line fails the length-prefix parse and is dropped
/// by the frame layer (ERR_OVERSIZE/ERR_MALFORMED), never sniffed.
/// Game keeps its own sniff for chunk server-to-server links.
namespace wirev2
{

/// Pack one logical message for a v2 socket: [u32 LE length][bytes].
/// No trailing delimiter. Empty on over-cap input (caller errors).
inline std::string packFramedMessage(const std::string &message)
{
    if (message.size() > protocol::kMaxFrameBytes)
    {
        return {};
    }
    std::string out;
    out.reserve(4 + message.size());
    const std::uint32_t n = static_cast<std::uint32_t>(message.size());
    out.push_back(static_cast<char>(n & 0xFF));
    out.push_back(static_cast<char>((n >> 8) & 0xFF));
    out.push_back(static_cast<char>((n >> 16) & 0xFF));
    out.push_back(static_cast<char>((n >> 24) & 0xFF));
    out += message;
    return out;
}

} // namespace wirev2
