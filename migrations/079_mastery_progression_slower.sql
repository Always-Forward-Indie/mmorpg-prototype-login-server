-- 079_mastery_progression_slower.sql
-- Slow mastery progression to ~10-15 hours for max mastery (100) on same-level mobs.
--  base_delta:  0.50 → 0.02  (~25× slower per-hit gain)
--  db_flush:    10   → 25    (less frequent DB writes)
--  tier values: unchanged (20/50/80/100)

UPDATE public.game_config SET value = '0.02' WHERE key = 'mastery.base_delta';
UPDATE public.game_config SET value = '25'   WHERE key = 'mastery.db_flush_every_hits';
