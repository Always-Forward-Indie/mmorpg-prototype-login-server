#pragma once

#include <pqxx/pqxx>
#include <stdexcept>

/// Thrown by Database helpers on query failure (query-name context included).
struct DatabaseError : std::runtime_error {
    using std::runtime_error::runtime_error;
};

/// Prepared-statement registrar: prepares all named queries from the
/// QueryRegistry on a pooled connection. Called by DatabasePool for each
/// (re)opened connection (prepared statements are per-connection in pqxx).
/// Former single-connection instance API (connect/getConnection/
/// executeQueryWithTransaction) was removed — all runtime queries go through
/// DatabasePool + exec_prepared with explicit empty() checks.
struct Database
{
    static void prepareQueriesOn(pqxx::connection &conn);

    Database() = delete;
};
