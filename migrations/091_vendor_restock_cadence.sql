-- 091_vendor_restock_cadence.sql
-- Cadence for the vendor restock tick (refills depleted shop slots per
-- restockAmount/restockIntervalSec; runtime stock is chunk-owned).
INSERT INTO public.game_config(key, value, value_type, description)
VALUES ('scheduler.vendor_restock_ms', '60000', 'int', 'Chunk vendor restock tick: refill depleted shop slots')
ON CONFLICT (key) DO NOTHING;
