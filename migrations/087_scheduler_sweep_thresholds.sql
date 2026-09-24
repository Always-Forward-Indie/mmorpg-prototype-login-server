-- 087_scheduler_sweep_thresholds.sql
-- Silence thresholds for the game-server liveness sweeps (companion to 086,
-- which covered the sweep periods). Sampled once at startup with compiled
-- fallbacks, so applying this migration changes nothing at runtime.

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.chunk_silent_threshold_ms', '180000', 'int', 'Game chunk-liveness sweep: drop chunks silent longer than this (3x 60s heartbeats)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.client_silent_threshold_ms', '600000', 'int', 'Game client-liveness sweep: evict clients silent longer than this (10 min)')
ON CONFLICT (key) DO NOTHING;
