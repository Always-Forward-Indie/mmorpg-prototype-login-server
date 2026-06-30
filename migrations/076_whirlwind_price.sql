-- 076_whirlwind_price.sql
-- Tome of Whirlwind (item 19) had vendor_price_buy=0 (intended as drop-only),
-- but migration 070 added it to Edrik's vendor inventory without a price override.
-- Set a proper buy price consistent with other rare skill books.

UPDATE public.items SET vendor_price_buy = 300 WHERE id = 19;
