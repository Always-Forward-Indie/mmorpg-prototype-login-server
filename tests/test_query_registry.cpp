// Unit tests for QueryRegistry (Step 3): prepared-statement SQL as pure
// data, verifiable without a database. No pqxx, no sockets.
#include "utils/QueryRegistry.hpp"

#include <gtest/gtest.h>
#include <regex>
#include <set>
#include <string>

namespace {

std::vector<int> placeholders(const std::string &sql) {
    static const std::regex re(R"(\$(\d+))");
    std::set<int> out;
    for (std::sregex_iterator it(sql.begin(), sql.end(), re), end; it != end; ++it)
        out.insert(std::stoi((*it)[1].str()));
    return {out.begin(), out.end()};
}

const QueryDef *findByName(const std::string &name) {
    for (const QueryDef *q = queryRegistryBegin(); q != queryRegistryEnd(); ++q)
        if (q->name == name)
            return q;
    return nullptr;
}

} // namespace

TEST(QueryRegistry, ExactCountAndNamesUnique) {
    EXPECT_EQ(queryRegistrySize(), 24u); // login catalog pin; bump on purpose
    std::set<std::string> names;
    for (const QueryDef *q = queryRegistryBegin(); q != queryRegistryEnd(); ++q) {
        EXPECT_FALSE(q->name.empty());
        EXPECT_FALSE(q->sql.empty());
        EXPECT_TRUE(names.insert(std::string(q->name)).second) << "duplicate: " << q->name;
    }
}

TEST(QueryRegistry, PlaceholdersContiguousFromOne) {
    for (const QueryDef *q = queryRegistryBegin(); q != queryRegistryEnd(); ++q) {
        auto ph = placeholders(std::string(q->sql));
        for (size_t i = 0; i < ph.size(); ++i)
            EXPECT_EQ(ph[i], static_cast<int>(i + 1)) << "query: " << q->name;
    }
}

TEST(QueryRegistry, AuthQueriesPresent) {
    const QueryDef *probe = findByName("probe_user_status");
    ASSERT_NE(probe, nullptr);
    EXPECT_NE(std::string(probe->sql).find("locked_until"), std::string::npos);

    EXPECT_NE(findByName("search_user"), nullptr);
    EXPECT_NE(findByName("register_user"), nullptr);
    EXPECT_NE(findByName("create_user_session"), nullptr);
}
