-- 090_wio_tick_cadence.sql
-- Cadence for the WIO tick (channeled-interaction completion + global
-- object respawns). Wired in ChunkServer (task id 23); previously
-- WorldObjectEventHandler::tick() had no callers at all.
INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.wio_tick_ms', '1000', 'int', 'Chunk WIO tick: complete finished channels + respawn depleted globals')
ON CONFLICT (key) DO NOTHING;
