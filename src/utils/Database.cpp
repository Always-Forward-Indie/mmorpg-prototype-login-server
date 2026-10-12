#include "utils/Database.hpp"
#include "utils/QueryRegistry.hpp"

void Database::prepareQueriesOn(pqxx::connection &conn)
{
    // Search user by login — returns user row including hashed password for verification in app code.
    // Also checks is_active and lock status (locked_until).
    // Registration order is preserved (see QueryRegistry).
    for (const QueryDef *q = queryRegistryBegin(); q != queryRegistryEnd(); ++q)
        conn.prepare(std::string(q->name), std::string(q->sql));
}
