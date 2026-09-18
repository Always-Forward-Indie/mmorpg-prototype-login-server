// Unit tests for AccountManager: pure validation + password hashing.
// No DB needed: validateRegistration and hashPassword are static.
#include "services/AccountManager.hpp"

#include <gtest/gtest.h>
#include <string>

namespace
{

const std::string kGoodPassword = "s3cur3-Pass!";
const std::string kGoodEmail = "bot@example.com";

} // namespace

TEST(ValidateRegistration, AcceptsValidInput)
{
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", kGoodPassword, kGoodEmail),
        AccountRegisterResult::OK);
    EXPECT_EQ(AccountManager::validateRegistration("abc", "12345678", ""),
        AccountRegisterResult::OK); // email optional
}

TEST(ValidateRegistration, RejectsBadLogins)
{
    EXPECT_EQ(AccountManager::validateRegistration("ab", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID); // too short
    EXPECT_EQ(AccountManager::validateRegistration("0123456789_abcdefghijX", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID); // 21 chars, too long
    EXPECT_EQ(AccountManager::validateRegistration("", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID);
    EXPECT_EQ(AccountManager::validateRegistration("bot-01", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID); // '-' not allowed
    EXPECT_EQ(AccountManager::validateRegistration("bot 01", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID); // space not allowed
    EXPECT_EQ(AccountManager::validateRegistration("бот01", kGoodPassword, kGoodEmail),
        AccountRegisterResult::ERR_LOGIN_INVALID); // non-ASCII not allowed
}

TEST(ValidateRegistration, AcceptsLoginBoundaries)
{
    EXPECT_EQ(AccountManager::validateRegistration("abc", kGoodPassword, ""),
        AccountRegisterResult::OK); // exactly 3
    EXPECT_EQ(AccountManager::validateRegistration("0123456789_abcdefghi", kGoodPassword, ""),
        AccountRegisterResult::OK); // exactly 20
    EXPECT_EQ(AccountManager::validateRegistration("A_Za_z09", kGoodPassword, ""),
        AccountRegisterResult::OK); // full charset
}

TEST(ValidateRegistration, RejectsBadPasswords)
{
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", "short7", kGoodEmail),
        AccountRegisterResult::ERR_PASSWORD_SHORT); // 7 chars
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", std::string(101, 'x'), kGoodEmail),
        AccountRegisterResult::ERR_PASSWORD_LONG); // 101 chars
}

TEST(ValidateRegistration, AcceptsPasswordBoundaries)
{
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", std::string(8, 'x'), ""),
        AccountRegisterResult::OK); // exactly 8
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", std::string(100, 'x'), ""),
        AccountRegisterResult::OK); // exactly 100
}

TEST(ValidateRegistration, RejectsMalformedEmail)
{
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", kGoodPassword, "not-an-email"),
        AccountRegisterResult::ERR_EMAIL_INVALID);
    EXPECT_EQ(AccountManager::validateRegistration("bot_01", kGoodPassword, "a@b@c"),
        AccountRegisterResult::OK); // only '@' presence is enforced
}

TEST(ValidateRegistration, LoginCheckedBeforePasswordAndEmail)
{
    // Order matters: callers (and registerAccount) see the login error first.
    EXPECT_EQ(AccountManager::validateRegistration("!!", "x", "nope"),
        AccountRegisterResult::ERR_LOGIN_INVALID);
}

TEST(HashPassword, IsDeterministicHex64)
{
    const std::string a = AccountManager::hashPassword("s3cur3-Pass!");
    const std::string b = AccountManager::hashPassword("s3cur3-Pass!");
    EXPECT_EQ(a, b);
    EXPECT_EQ(a.size(), 64u);
    EXPECT_TRUE(a.find_first_not_of("0123456789abcdef") == std::string::npos);
}

TEST(HashPassword, DiffersPerInput)
{
    EXPECT_NE(AccountManager::hashPassword("password1"), AccountManager::hashPassword("password2"));
    EXPECT_NE(AccountManager::hashPassword(""), AccountManager::hashPassword(" "));
}

TEST(HashPassword, MatchesKnownSha256Vector)
{
    // SHA-256("") — well-known test vector; guards against silent algo swaps.
    EXPECT_EQ(AccountManager::hashPassword(""),
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
}
