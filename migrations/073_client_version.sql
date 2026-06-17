-- Migration 073: Add client_version columns for version validation
-- Stores the client version reported during authentication and registration.
-- users.client_version: last version used to log in / register
-- user_sessions.client_version: per-session version tracking

BEGIN;

ALTER TABLE public.users ADD COLUMN client_version VARCHAR(32);
ALTER TABLE public.user_sessions ADD COLUMN client_version VARCHAR(32);

COMMIT;
