-- Migration 071: Character online status + playtime tracking
-- Renames play_time_sec → total_play_time_sec
-- Adds last_session_play_time_sec, is_online

BEGIN;

ALTER TABLE public.characters RENAME COLUMN play_time_sec TO total_play_time_sec;

ALTER TABLE public.characters ADD COLUMN last_session_play_time_sec bigint DEFAULT 0 NOT NULL;
ALTER TABLE public.characters ADD COLUMN is_online boolean DEFAULT false NOT NULL;

COMMENT ON COLUMN public.characters.total_play_time_sec IS 'Суммарное время игры в секундах';
COMMENT ON COLUMN public.characters.last_session_play_time_sec IS 'Время проведённое в игре за последнюю сессию в секундах';
COMMENT ON COLUMN public.characters.is_online IS 'Находится ли персонаж в игре в данный момент';

COMMIT;

-- Index must be created outside of a transaction block
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_characters_is_online ON public.characters (is_online) WHERE is_online = true;
