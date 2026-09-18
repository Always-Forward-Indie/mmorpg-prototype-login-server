// Compile-time contract for DatabasePool::Guard (no live DB needed):
// guards must be movable (returned by value from acquire()) and non-copyable.
#include "utils/DatabasePool.hpp"

#include <gtest/gtest.h>
#include <type_traits>

static_assert(std::is_move_constructible_v<DatabasePool::Guard>,
    "Guard must be move-constructible (acquire() returns by value)");
static_assert(std::is_move_assignable_v<DatabasePool::Guard>,
    "Guard must support move-assign (takeover without leaking the slot)");
static_assert(!std::is_copy_constructible_v<DatabasePool::Guard>,
    "Guard must be non-copyable (double-release otherwise)");
static_assert(!std::is_copy_assignable_v<DatabasePool::Guard>,
    "Guard must be non-copy-assignable");

TEST(DatabasePool, GuardTraitsEnforcedAtCompileTime)
{
    SUCCEED();
}
