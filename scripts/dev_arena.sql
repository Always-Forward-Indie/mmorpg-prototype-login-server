-- ============================================================================
-- DEV-ONLY test content: champion arena (foxes, threshold 5).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_arena.sql
-- Then bounce game-server + chunk-server (static push happens at chunk boot).
--
-- What: game zone test_arena (RECT 4638..4838 x -1025..-825, threshold 5)
-- + spawn zone 'Test Arena Foxes' (same box, 3x ForestFox template 4,
-- respawn 1 min). Placement is the free lens between village CIRCLE and
-- fields ANNULUS hole (corners clear both shapes by 35-100u, verified by
-- exact math) — minutes on foot from the village, no overlap with prod
-- zones (first-match lookups elsewhere unaffected). Fox separation is
-- 250u so only a few fit: steady trickle, threshold 5 in minutes.
-- (Prod Fox Glade is a 5-8km annulus where 100 kills are effectively
-- unreachable — see SERVER_BUGS #8.)
-- Idempotent: re-runnable (deletes its own rows by slug first).
-- Test id range 9001+ (documented, setval'd past to avoid seq collisions).
-- ============================================================================

BEGIN;

-- Clean previous application (order: children first).
DELETE FROM spawn_zone_mobs WHERE spawn_zone_id = 9001;
DELETE FROM spawn_zones WHERE zone_id = 9001;
DELETE FROM zones WHERE id = 9001;

-- Game zone: isolated RECT far from prod zones (forest ends ~28k).
INSERT INTO zones (id, slug, name, min_level, max_level, is_pvp, is_safe_zone,
                   min_x, max_x, min_y, max_y,
                   exploration_xp_reward, champion_threshold_kills,
                   shape_type, center_x, center_y, inner_radius, outer_radius)
VALUES (9001, 'test_arena', 'Test Arena (DEV ONLY)', 1, 999, false, false,
        4638, 4838, -1025, -825,
        0, 5,
        'RECT', 4738, -925, 0, 0);

-- Spawn zone: dense RECT inside it.
INSERT INTO spawn_zones (zone_id, zone_name,
                         min_spawn_x, min_spawn_y, min_spawn_z,
                         max_spawn_x, max_spawn_y, max_spawn_z,
                         game_zone_id, shape_type,
                         center_x, center_y, inner_radius, outer_radius,
                         exclusion_game_zone_id)
VALUES (9001, 'Test Arena Foxes',
        4638, -1025, 250,
        4838, -825, 350,
        9001, 'RECT',
        4738, -925, 0, 0,
        NULL);

-- 3 foxes, 1-minute respawn (250u separation fits a few at a time).
INSERT INTO spawn_zone_mobs (spawn_zone_id, mob_id, spawn_count, respawn_time)
VALUES (9001, 4, 3, '00:01:00');

-- Keep sequences past the test range.
SELECT setval('zones_id_seq', GREATEST((SELECT last_value FROM zones_id_seq), 9100));
SELECT setval('spawn_zones_zone_id_seq', GREATEST((SELECT last_value FROM spawn_zones_zone_id_seq), 9100));

COMMIT;

-- Verification (expect 1 row each, threshold 5, count 3).
SELECT id, slug, champion_threshold_kills FROM zones WHERE id = 9001;
SELECT zone_id, zone_name, game_zone_id, shape_type FROM spawn_zones WHERE zone_id = 9001;
SELECT spawn_zone_id, mob_id, spawn_count FROM spawn_zone_mobs WHERE spawn_zone_id = 9001;
