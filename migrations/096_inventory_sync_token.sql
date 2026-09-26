-- 096_inventory_sync_token.sql
-- Idempotency key for chunk inventory rows (S-batch A4 fix).
-- Problem: player_inventory was UNIQUE(character_id, item_id), so two
-- instances of a non-stackable item (same template) collapsed into one row:
-- the second instance was lost on the next login. Chunk stamps a
-- per-instance syncToken (random-start uint64, never 0 = legacy rows);
-- the game keys INSERT-or-SELECT on (character_id, sync_token) instead of
-- the template pair, so every instance survives and resends converge.
-- The template-pair unique index is DROPPED: with per-instance identity it
-- is both wrong (forbids real duplicates) and unnecessary (stackables stay
-- single-row via token identity — chunk stacks in memory before saving).
-- Legacy token-less saves resolve by SELECT-then-UPDATE/INSERT in the
-- handler (same single-writer ordering as before, documented race note).
ALTER TABLE public.player_inventory
    ADD COLUMN IF NOT EXISTS sync_token BIGINT UNIQUE NULL;
DROP INDEX IF EXISTS public.idx_player_inventory_unique;

COMMENT ON COLUMN public.player_inventory.sync_token IS
'Chunk id-sync token: per-instance idempotency key (NULL = legacy row).';
