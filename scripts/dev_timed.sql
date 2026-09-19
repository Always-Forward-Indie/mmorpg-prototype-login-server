-- ============================================================================
-- DEV-ONLY test content: fast timed-champion cycle (~3 min, not 4/6 h).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_timed.sql
-- Then restart chunk-server so it re-pulls templates from game-server
-- (templates push on handshake; the 30 s tick alone only re-reads memory).
--
-- What: timed template 'dev_timed_fox' (id 9001) in the test arena (zone
-- 9001, needs scripts/dev_arena.sql applied first) with next_spawn_at =
-- now+120 s. Expected live sequence within ~3 min of chunk restart:
--   preAnnounce (champion_spawned_soon, window 5 min covers 120 s) →
--   Spawned (world_notification) → kill it → TIMED_CHAMPION_KILLED re-arms
--   next_spawn_at = killedAt + interval (interval_hours = 1 keeps the range
--   quiet after the first cycle).
-- Cleanup: DELETE FROM timed_champion_templates WHERE id = 9001;
-- Idempotent: re-runnable (deletes its own row by id first).
-- Test id range 9000+ (documented, setval'd past to avoid seq collisions).
-- ============================================================================

BEGIN;

-- Clean previous application.
DELETE FROM timed_champion_templates WHERE id = 9001;

-- Dev timed row: arena foxes, fires ~2 min after chunk reload.
INSERT INTO timed_champion_templates (id, slug, zone_id, mob_template_id,
                                      interval_hours, window_minutes,
                                      next_spawn_at, announcement_key)
VALUES (9001, 'dev_timed_fox', 9001, 4,
        1, 5,
        EXTRACT(EPOCH FROM NOW() + INTERVAL '120 seconds')::bigint,
        'champion.dev_timed_fox');

-- Keep sequence past the test range.
SELECT setval('timed_champion_templates_id_seq',
              GREATEST((SELECT last_value FROM timed_champion_templates_id_seq), 9100));

COMMIT;

-- Verification (expect 1 row, next_spawn_at ~ now+120).
SELECT id, slug, zone_id, interval_hours, next_spawn_at,
       to_timestamp(next_spawn_at) - NOW() AS fires_in
FROM timed_champion_templates WHERE id = 9001;
