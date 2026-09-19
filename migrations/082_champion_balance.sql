-- 082_champion_balance.sql
-- Champion content balance, part 1 (option C+A, approved):
--   A: farmable thresholds on prod hunting zones (100 -> 25). Village (id 1,
--      safe zone) stays 100. Code default stays 100 (COALESCE in
--      game-server Database.cpp) — this migration only retunes content rows.
--   C: initialise next_spawn_at for timed templates (NULL = skipped every
--      tick, so timed champions never fire). Seeds now + interval_hours;
--      after that the kill cycle self-sustains via TIMED_CHAMPION_KILLED
--      (game-server EventHandler recomputes killedAt + interval).
-- Idempotent: A is a plain retune of known rows; C only touches NULL rows.
-- NOTE: scripts/db.sh dump appends a next_spawn_at=NULL reset for fresh
-- deploys — on a fresh database this migration re-seeds the schedule at
-- deploy time, which is the intended behaviour (timed starts ticking).

BEGIN;

-- A: prod hunting zones 100 -> 25 (village stays 100).
UPDATE public.zones SET champion_threshold_kills = 25 WHERE id IN (2, 6, 7);

-- C: seed NULL timed schedules (ancient_bear 4h, awakened_golem 6h).
UPDATE public.timed_champion_templates
SET next_spawn_at = EXTRACT(EPOCH FROM NOW() + (interval_hours || ' hours')::interval)::bigint
WHERE next_spawn_at IS NULL;

COMMIT;

-- Verification (expect 25/25/25 + two non-NULL next_spawn_at).
-- SELECT id, slug, champion_threshold_kills FROM public.zones WHERE id IN (1, 2, 6, 7) ORDER BY id;
-- SELECT slug, interval_hours, next_spawn_at, to_timestamp(next_spawn_at) - NOW() AS fires_in
--   FROM public.timed_champion_templates ORDER BY id;
