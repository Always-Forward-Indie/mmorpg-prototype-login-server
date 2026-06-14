-- Migration 072: Remove unused columns
-- Drops characters.radius (unused; mobs have their own mob.radius)
-- Drops users.is_email_verified (never referenced in application code)

BEGIN;

ALTER TABLE public.characters DROP COLUMN radius;
ALTER TABLE public.users DROP COLUMN is_email_verified;

COMMIT;
