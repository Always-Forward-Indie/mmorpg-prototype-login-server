-- 095_inv_sync_retry_cadence.sql
-- Cadence for the chunk inventory id-sync retry sweep (re-emits
-- saveInventoryChange for rows still awaiting their inventoryItemIdSync
-- echo; game-side upsert is absolute-SET so resends converge).
INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.inv_sync_retry_ms', '5000', 'int', 'Chunk inventory id-sync retry sweep: resend saves missing their id echo')
ON CONFLICT (key) DO NOTHING;
