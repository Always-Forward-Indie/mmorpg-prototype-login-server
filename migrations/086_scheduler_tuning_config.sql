-- 086_scheduler_tuning_config.sql
-- Scheduler periodic-task intervals as game_config knobs.
-- ChunkServer samples scheduler.*_ms once at schedule time (getInt with the
-- compiled literal as fallback); game-server main samples
-- scheduler.*_sec the same way. All rows mirror the compiled defaults, so
-- applying this migration changes nothing at runtime — it only makes the
-- cadences tunable without a rebuild (GM set_config + restart, or live
-- where the reader samples per tick).
-- Login's session_cleanup_ms lives in config.json/ENV (LoginServerConfig),
-- not in game_config — login has no game_config reader.

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.spawn_safety_ms', '300000', 'int', 'Chunk spawn safety sweep: spawn where alive<totalSpawnCount (5 min)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.respawn_ms', '30000', 'int', 'Chunk respawn-timed fill of non-full zones')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.mob_tick_ms', '50', 'int', 'Chunk unified mob movement + broadcast tick resolution (per-mob gating inside)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.combat_ms', '100', 'int', 'Chunk ongoing-actions (instant-skill/cast resolution) tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.cleanup_ms', '10000', 'int', 'Chunk periodic cleanup of inactive sessions and client data')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.harvest_ms', '1000', 'int', 'Chunk harvest progress + corpse cleanup tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.drop_cleanup_ms', '60000', 'int', 'Chunk expired ground-item cleanup tick (TTL itself: drop.ttl_sec)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.dead_mob_ms', '5000', 'int', 'Chunk dead-mob corpse-expiry check (TTL itself: corpse.ttl_ms)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.mem_monitor_ms', '5000', 'int', 'Chunk VmRSS memory-monitor log tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.aggressive_cleanup_ms', '30000', 'int', 'Chunk aggressive memory cleanup (forceCleanup + malloc_trim) tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.save_positions_ms', '30000', 'int', 'Chunk savePositions push to game-server for online chars')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.dialogue_cleanup_ms', '60000', 'int', 'Chunk expired dialogue-session cleanup tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.trade_cleanup_ms', '30000', 'int', 'Chunk expired trade-session cleanup tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.rep_snapshot_ms', '60000', 'int', 'Chunk absolute reputation snapshot push (delta-loss bound)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.quest_flush_ms', '5000', 'int', 'Chunk dirty quest-progress + pending-flags flush tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.dead_sockets_ms', '30000', 'int', 'Chunk dead-socket cleanup (off hot broadcast path) tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.save_hp_mana_ms', '10000', 'int', 'Chunk saveHpMana push to game-server for online chars')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.save_playtime_ms', '60000', 'int', 'Chunk savePlayTime delta push tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.timed_champion_ms', '30000', 'int', 'Chunk timed-champion window + pre-announce tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.survival_evo_ms', '300000', 'int', 'Chunk survival-champion evolution tick (5 min)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.zone_event_ms', '30000', 'int', 'Chunk zone-event scheduler tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.ping_sweep_ms', '15000', 'int', 'Chunk ping-timeout client reap tick (threshold: 30s in code)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.ghost_cleanup_ms', '30000', 'int', 'Chunk ghost-character (orphaned join) cleanup tick')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.chunk_sweep_sec', '60', 'int', 'Game chunk-liveness sweep period in seconds (threshold: silent 180s)')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.client_sweep_sec', '60', 'int', 'Game client-liveness sweep period in seconds (threshold: silent 600s)')
ON CONFLICT (key) DO NOTHING;
