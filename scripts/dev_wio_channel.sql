-- ============================================================================
-- DEV-ONLY test content: channeled WIO object (tick-completion pin).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_wio_channel.sql
-- Then reload world content (NO restart): admin op reloadWorldContent via
-- gm_bot (chunk merges objects by id; runtime states reset).
--
-- What: 9003 'dev_channel_stone' (channeled, global, min_level 1, huge
-- radius so the contract test needs no walking, 5 s channel, 30 s
-- respawn). Interact -> channeled start ack -> WIO tick (1 s) completes
-- -> worldObjectInteractResult{channeled_complete} -> object depletes ->
-- respawns after 30 s (self-healing reruns: poll for availability).
-- Idempotent: re-runnable (deletes its own row by id first).
-- Test id range 9000+ (documented, setval'd past to avoid seq collisions).
-- ============================================================================

BEGIN;

DELETE FROM world_objects WHERE id = 9003;

-- NOTE: zone_id must be non-NULL (game boot push does .as<int>() on it
-- and throws the whole push on NULL). Village (1) is fine for fixtures.
INSERT INTO world_objects (id, slug, name_key, object_type, scope,
                           pos_x, pos_y, pos_z, rot_z, zone_id,
                           dialogue_id, loot_table_id, required_item_id,
                           interaction_radius, channel_time_sec, respawn_sec,
                           is_active_by_default, min_level)
VALUES (9003, 'dev_channel_stone', 'dev.channel', 'channeled', 'global',
        100, 100, 200, 0, 1,
        NULL, NULL, NULL,
        50000, 5, 30,
        true, 1);

COMMIT;

-- Verification (expect 1 row).
SELECT id, slug, object_type, channel_time_sec, respawn_sec
FROM world_objects WHERE id = 9003;
