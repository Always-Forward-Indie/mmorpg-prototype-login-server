-- ============================================================================
-- DEV-ONLY test content: short-cycle restock slot (live restock pin).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_restock.sql
-- Then reload world content (NO restart): admin op reloadWorldContent via
-- gm_bot, or bounce chunk-server (static push happens at chunk boot).
--
-- What: Theron (vendor_npc 2) gains small_health_potion (item 46),
-- stock 2/2, refill +2 every 60 s. Chunk VendorManager serves runtime
-- stock from the push; buys never touch this row (stock_count is the
-- seed — runtime depletes in memory, tickRestock refills).
-- Idempotent: re-runnable (deletes its own row by vendor+item first).
-- ============================================================================

BEGIN;

DELETE FROM public.vendor_inventory WHERE vendor_npc_id = 2 AND item_id = 46;

INSERT INTO public.vendor_inventory
    (vendor_npc_id, item_id, stock_count, price_override,
     restock_amount, stock_max, restock_interval_sec, last_restock_at)
VALUES (2, 46, 2, NULL, 2, 2, 60, NULL);

COMMIT;

-- Verification (expect one row: 2/2/2/60).
SELECT vendor_npc_id, item_id, stock_count, stock_max, restock_amount,
       restock_interval_sec
FROM public.vendor_inventory WHERE vendor_npc_id = 2 AND item_id = 46;
