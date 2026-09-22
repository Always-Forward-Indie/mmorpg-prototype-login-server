#include "utils/QueryRegistry.hpp"

namespace {

// 24 prepared statements.
const QueryDef kQueries[] = {
        // Search user by login — returns user row including hashed password for verification in app code.
        // Also checks is_active and lock status (locked_until).
    {"search_user",
     R"QDEF(SELECT id, login, password, role, is_active, locked_until, failed_login_attempts FROM users WHERE login = $1 AND is_active = true AND (locked_until IS NULL OR locked_until < now()) LIMIT 1;)QDEF"},
        // Lock/inactive probe: distinguishes LOCKED from INVALID_CREDENTIALS when
        // search_user returns empty (locked accounts are filtered above).
        // Read-only, used by Authenticator triage; wire stays generic.
    {"probe_user_status",
     R"QDEF(SELECT is_active, locked_until FROM users WHERE login = $1 LIMIT 1;)QDEF"},
    {"increment_failed_logins",
     R"QDEF(UPDATE users SET failed_login_attempts = failed_login_attempts + 1, locked_until = CASE WHEN failed_login_attempts + 1 >= 5   THEN now() + interval '15 minutes' ELSE locked_until END WHERE login = $1;)QDEF"},
    {"reset_failed_logins",
     R"QDEF(UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login = now(), last_login_ip = $2::inet, client_version = $3 WHERE id = $1;)QDEF"},
    {"create_user_session",
     R"QDEF(INSERT INTO user_sessions (user_id, token_hash, client_version, created_at, expires_at) VALUES ($1, $2, $3, now(), now() + interval '30 days') ON CONFLICT (token_hash) DO NOTHING;)QDEF"},
    {"cleanup_expired_sessions",
     R"QDEF(DELETE FROM user_sessions WHERE expires_at < NOW() AND revoked_at IS NULL;)QDEF"},
    {"revoke_user_sessions",
     R"QDEF(UPDATE user_sessions SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW();)QDEF"},
    {"get_characters_list",
     R"QDEF(SELECT c.id AS character_id, c.level AS character_lvl, c.name AS character_name, cc.slug AS class_slug, r.slug AS race_slug, cg.name AS gender_slug, c.experience_points, c.account_slot, c.is_online, COALESCE(ccs.current_health, 1) AS current_health, COALESCE(ccs.current_mana, 1) AS current_mana FROM characters c JOIN character_class cc ON c.class_id = cc.id JOIN race r ON c.race_id = r.id LEFT JOIN character_genders cg ON cg.id = c.gender LEFT JOIN character_current_state ccs ON ccs.character_id = c.id WHERE c.owner_id = $1 AND c.deleted_at IS NULL ORDER BY c.account_slot;)QDEF"},
        // get_character_equipment_preview — returns equipped items (slotId + itemSlug) for a single character.
        // Used to build the character-selection preview on the client.
        // Param: $1=character_id
    {"get_character_equipment_preview",
     R"QDEF(SELECT ce.equip_slot_id AS slot_id, i.slug AS item_slug FROM character_equipment ce JOIN player_inventory pi ON pi.id = ce.inventory_item_id JOIN items i ON i.id = pi.item_id WHERE ce.character_id = $1 ORDER BY ce.equip_slot_id;)QDEF"},
    {"select_character",
     R"QDEF(SELECT c.id AS character_id, c.level AS character_lvl, c.name AS character_name, cc.name AS character_class, r.name AS race_name, c.experience_points, c.account_slot FROM characters c JOIN character_class cc ON c.class_id = cc.id JOIN race r ON c.race_id = r.id WHERE c.owner_id = $1 AND c.id = $2 AND c.deleted_at IS NULL LIMIT 1;)QDEF"},
        // create_character — inserts base record; resolves class/race/gender by slug.
        // Params: $1=owner_id(int), $2=character_name, $3=class_slug, $4=race_slug, $5=gender_slug (= gender name)
        // level is always set to 1 (default was 0 which is invalid).
    {"create_character",
     R"QDEF(INSERT INTO characters (owner_id, name, class_id, race_id, gender, account_slot, level) SELECT $1::int, $2, cc.id, r.id, cg.id,   COALESCE((SELECT MAX(account_slot) + 1 FROM characters WHERE owner_id = $1::int AND deleted_at IS NULL), 1),   1 FROM character_class cc JOIN race r ON r.slug = $4 JOIN character_genders cg ON cg.name = $5 WHERE cc.slug = $3 RETURNING id;)QDEF"},
        // init_character_state — called after create_character to set up health/mana state row
    {"init_character_state",
     R"QDEF(INSERT INTO character_current_state (character_id, current_health, current_mana) VALUES ($1, 1, 1) ON CONFLICT (character_id) DO NOTHING;)QDEF"},
        // init_character_position — creates default position row (0,0,0 zone=1 village)
    {"init_character_position",
     R"QDEF(INSERT INTO character_position (character_id, x, y, z, zone_id) VALUES ($1, 0, 0, 200, 1) ON CONFLICT DO NOTHING;)QDEF"},
        // init_character_default_skills — grants all is_default=true skills for the character's class
        // Params: $1=character_id, $2=class_id
    {"init_character_default_skills",
     R"QDEF(INSERT INTO character_skills (character_id, skill_id, current_level) SELECT $1::bigint, skill_id, 1 FROM class_skill_tree WHERE class_id = $2::int AND is_default = true ON CONFLICT DO NOTHING;)QDEF"},
        // get_class_id_by_slug — resolve class slug → class_id for use in skill/item init
    {"get_class_id_by_slug",
     R"QDEF(SELECT id FROM character_class WHERE slug = $1 LIMIT 1;)QDEF"},
        // init_character_starter_items — grants class starter items from class_starter_items table
        // Params: $1=character_id, $2=class_id
    {"init_character_starter_items",
     R"QDEF(INSERT INTO player_inventory (character_id, item_id, quantity, slot_index, durability_current) SELECT $1::bigint, csi.item_id, csi.quantity, csi.slot_index,   COALESCE(csi.durability_current, i.durability_max) FROM class_starter_items csi JOIN items i ON i.id = csi.item_id WHERE csi.class_id = $2::int;)QDEF"},
        // check_character_name_exists — uniqueness check (case-insensitive), excludes soft-deleted
    {"check_character_name_exists",
     R"QDEF(SELECT 1 FROM characters WHERE lower(name) = lower($1) AND deleted_at IS NULL LIMIT 1;)QDEF"},
        // get_character_slot_count — current number of alive characters per account
    {"get_character_slot_count",
     R"QDEF(SELECT COUNT(*) FROM characters WHERE owner_id = $1::int AND deleted_at IS NULL;)QDEF"},
        // delete_character — soft-delete; only the owning account may delete
        // Params: $1=character_id, $2=account_id (owner guard)
    {"delete_character",
     R"QDEF(UPDATE characters SET deleted_at = now() WHERE id = $1::bigint AND owner_id = $2::int AND deleted_at IS NULL RETURNING id;)QDEF"},
        // get_character_classes — full list of playable classes for character creation screen
    {"get_character_classes",
     R"QDEF(SELECT id, name, slug, description FROM character_class ORDER BY id;)QDEF"},
        // get_character_races — full list of playable races
    {"get_character_races",
     R"QDEF(SELECT id, name, slug FROM race ORDER BY id;)QDEF"},
        // get_character_genders — full list of gender options
    {"get_character_genders",
     R"QDEF(SELECT id, name, label FROM character_genders ORDER BY id;)QDEF"},
        // check_login_available — case-insensitive uniqueness check for registration
    {"check_login_available",
     R"QDEF(SELECT 1 FROM users WHERE lower(login) = lower($1) LIMIT 1;)QDEF"},
        // register_user — create a new account (password must already be hashed by the application)
        // Params: $1=login, $2=password_hash, $3=email (may be empty), $4=registration_ip, $5=client_version
    {"register_user",
     R"QDEF(INSERT INTO users (login, password, email, registration_ip, client_version, is_active) VALUES ($1, $2, NULLIF($3, ''), $4::inet, $5, true) RETURNING id;)QDEF"},
};

} // namespace

const QueryDef *queryRegistryBegin() { return kQueries; }
const QueryDef *queryRegistryEnd()
{
    return kQueries + sizeof(kQueries) / sizeof(kQueries[0]);
}
