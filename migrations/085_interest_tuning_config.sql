-- 085_interest_tuning_config.sql
-- Interest v2 (spatial subscriptions) live-tuning knobs in game_config.
-- ChunkServer configures InterestManager from these at startup with
-- InterestManager::kDefault* fallbacks, so all six rows mirror the compiled
-- defaults. Prior state: only interest.enabled existed (and only in live DB,
-- never in the canonical dump) — the other five silently used fallbacks.
-- After applying, fresh deploys (dump) and existing DBs (this migration)
-- converge on the same values.

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.cell_size', '1500.0', 'float', 'Interest v2 grid cell size in world units (3x3 neighbourhood at view_radius=1)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.view_radius', '1', 'int', 'Interest v2 view radius in cells (1 = 3x3 neighbourhood around anchor cell)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.rehome_margin_frac', '0.15', 'float', 'Interest v2 anchor rehome margin as fraction of cell size (anti-jitter on cell borders)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.enabled', 'true', 'bool', 'Interest v2 master switch (false = legacy broadcast-all fail-open)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.snapshots', 'true', 'bool', 'Interest v2 enter-snapshots for newly subscribed cells')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('interest.snapshot_cooldown_ms', '2000', 'int', 'Interest v2 enter-snapshot gate: at most one snapshot per client per N ms')
ON CONFLICT (key) DO NOTHING;

-- Verification (expect 6 rows).
-- SELECT key, value FROM public.game_config WHERE key LIKE 'interest.%' ORDER BY key;
