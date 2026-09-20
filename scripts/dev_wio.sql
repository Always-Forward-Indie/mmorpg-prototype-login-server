-- ============================================================================
-- DEV-ONLY test content: WIO examine fixtures (no dialogue -> ack success).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_wio.sql
-- Then restart chunk-server (objects load on handshake boot push).
--
-- What: 9001 'dev_examine_stone' (examine, global, min_level 1, huge
-- radius so the contract test needs no walking) + 9002 'dev_far_stone'
-- (same, tiny radius at a remote corner for the TOO_FAR path).
-- Idempotent: re-runnable (deletes its own rows by id first).
-- Test id range 9000+ (documented).
-- ============================================================================

BEGIN;

DELETE FROM world_objects WHERE id IN (9001, 9002);

-- NOTE: zone_id must be non-NULL (game boot push does .as<int>() on it
-- and throws the whole push on NULL). Village (1) is fine for fixtures.
INSERT INTO world_objects (id, slug, name_key, object_type, scope,
                           pos_x, pos_y, pos_z, rot_z, zone_id,
                           dialogue_id, loot_table_id, required_item_id,
                           interaction_radius, channel_time_sec, respawn_sec,
                           is_active_by_default, min_level)
VALUES (9001, 'dev_examine_stone', 'dev.examine', 'examine', 'global',
        0, 0, 200, 0, 1,
        NULL, NULL, NULL,
        50000, 0, 0,
        true, 1),
       (9002, 'dev_far_stone', 'dev.far', 'examine', 'global',
        28000, 28000, 200, 0, 1,
        NULL, NULL, NULL,
        100, 0, 0,
        true, 1);

COMMIT;

-- Verification (expect 2 rows).
SELECT id, slug, object_type, interaction_radius FROM world_objects WHERE id IN (9001, 9002) ORDER BY id;
