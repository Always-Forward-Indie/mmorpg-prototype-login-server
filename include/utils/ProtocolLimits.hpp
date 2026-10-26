#pragma once

#include <cstddef>

/// Single source of truth for wire-protocol framing limits.
///
/// Mirrors `mmorpg-prototype-integration-tests/proto/mmo_proto.py`:
/// one JSON object per line, `\n`-terminated, UTF-8, max 8KB/message.
/// Servers previously used 1024 bytes and silently dropped larger packets,
/// which hung clients until timeout. Now oversize/malformed packets get an
/// explicit `ERR_OVERSIZE` / `ERR_MALFORMED` error response.
namespace protocol {

/// Max bytes per single `\n`-framed JSON message (8KB, matches test harness).
inline constexpr std::size_t kMaxMessageBytes = 8 * 1024;

/// Max bytes buffered per connection without a `\n` delimiter.
/// Prevents a malicious/buggy client from growing `socketBuffers_` unboundedly
/// by never sending a newline (DoS). On overflow the buffer is dropped with
/// an `ERR_OVERSIZE` response and the connection stays alive.
inline constexpr std::size_t kMaxAccumulatedBytes = 64 * 1024;

/// Protocol v2 (S14, chunk docs/api/14-framing-v2-protocol.md): length-prefixed
/// frames `[u32 LE length][UTF-8 JSON]`, no `\n` delimiter.
inline constexpr std::size_t kMaxFrameBytes = 4 * 1024 * 1024;

/// v2: max buffered per connection (a legit frame can be up to 4MB and
/// arrives in 8KB TCP chunks — the v1 cap would kill it mid-stream).
inline constexpr std::size_t kMaxAccumulatedBytesV2 = kMaxFrameBytes + 64 * 1024;

/// v2 framing version offered/selected in joinGameClient `body.framing`.
inline constexpr int kFramingV2 = 2;

/// Read chunk size for `async_read_some`. Larger than before to reduce
/// syscalls; framing is still enforced per-message above.
inline constexpr std::size_t kReadChunkBytes = 8 * 1024;

/// Wire error codes for framing failures (protocol v1, additive only).
inline constexpr const char *kErrOversize = "ERR_OVERSIZE";
inline constexpr const char *kErrMalformed = "ERR_MALFORMED";

/// Error-shape convention (additive, old clients ignore unknown body keys):
/// every `status:error` response carries `body.errorCode` mirroring
/// `header.message` (injected centrally in `generateResponseMessage`;
/// framing paths set it directly). Version rejects additionally carry
/// `body.serverVersion/minClientVersion/maxClientVersion`.

/// Protocol version echoed in `header.version`.
inline constexpr const char *kProtocolVersion = "1.0";

} // namespace protocol
