-- Migration 074: Consolidate inventory item stacks
-- Adds a UNIQUE constraint on (character_id, item_id) to prevent duplicate
-- inventory rows for the same item. Also cleans up pre-existing duplicates.

BEGIN;

-- 1. Merge existing duplicates: keep one row per (character_id, item_id) with summed quantity
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT character_id, item_id, SUM(quantity) AS total_qty, COUNT(*) AS cnt
        FROM player_inventory
        GROUP BY character_id, item_id
        HAVING COUNT(*) > 1
    LOOP
        -- Delete all rows
        DELETE FROM player_inventory
        WHERE character_id = r.character_id AND item_id = r.item_id;
        -- Re-insert one merged row
        INSERT INTO player_inventory (character_id, item_id, quantity)
        VALUES (r.character_id, r.item_id, r.total_qty);
    END LOOP;
END;
$$;

-- 2. Add unique index to prevent future duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_inventory_unique
    ON player_inventory (character_id, item_id);

COMMIT;
