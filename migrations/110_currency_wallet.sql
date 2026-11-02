-- 110_currency_wallet.sql — AAA currency: wallet ledger, full removal of gold_coin-as-item.
-- Gold becomes a ledger balance in character_currencies, not a player_inventory row.
-- No backward compat, no dual-write (dev cutover).

-- 1. Currency catalog
CREATE TABLE IF NOT EXISTS public.currencies (
    id SERIAL PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    decimals INT NOT NULL DEFAULT 0,
    max_balance BIGINT NOT NULL DEFAULT 999999999,
    tradable_in_trade BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE public.currencies IS 'Каталог валют (кошелёк). Балансы — в character_currencies, не в player_inventory.';

INSERT INTO public.currencies (slug, name)
VALUES ('gold', 'Gold')
ON CONFLICT (slug) DO NOTHING;

-- 2. Wallet balances
CREATE TABLE IF NOT EXISTS public.character_currencies (
    character_id BIGINT NOT NULL REFERENCES public.characters(id) ON DELETE CASCADE,
    currency_id INT NOT NULL REFERENCES public.currencies(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL DEFAULT 0 CHECK (amount >= 0),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (character_id, currency_id)
);
COMMENT ON TABLE public.character_currencies IS 'Кошелёк персонажа: одна строка на валюту. Единственный источник баланса.';

-- 3. Starter wallet grants (replaces gold rows in class_starter_items)
CREATE TABLE IF NOT EXISTS public.class_starter_currencies (
    class_id INT NOT NULL,
    currency_id INT NOT NULL REFERENCES public.currencies(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL DEFAULT 0 CHECK (amount >= 0),
    PRIMARY KEY (class_id, currency_id)
);

-- 4. Backfill wallet from legacy gold_coin inventory rows
INSERT INTO public.character_currencies (character_id, currency_id, amount)
SELECT pi.character_id, c.id, SUM(pi.quantity)::BIGINT
FROM public.player_inventory pi
JOIN public.items i ON i.id = pi.item_id AND i.slug = 'gold_coin'
JOIN public.currencies c ON c.slug = 'gold'
GROUP BY pi.character_id, c.id
ON CONFLICT (character_id, currency_id)
DO UPDATE SET amount = public.character_currencies.amount + EXCLUDED.amount;

-- 5. Migrate starter gold into starter wallet table
INSERT INTO public.class_starter_currencies (class_id, currency_id, amount)
SELECT csi.class_id, c.id, SUM(csi.quantity)::BIGINT
FROM public.class_starter_items csi
JOIN public.items i ON i.id = csi.item_id AND i.slug = 'gold_coin'
JOIN public.currencies c ON c.slug = 'gold'
GROUP BY csi.class_id, c.id
ON CONFLICT (class_id, currency_id)
DO UPDATE SET amount = EXCLUDED.amount;

-- 6. Drop legacy gold rows everywhere it behaved as an item
DELETE FROM public.class_starter_items
WHERE item_id IN (SELECT id FROM public.items WHERE slug = 'gold_coin');

DELETE FROM public.mob_loot_info
WHERE item_id IN (SELECT id FROM public.items WHERE slug = 'gold_coin');

DELETE FROM public.player_inventory
WHERE item_id IN (SELECT id FROM public.items WHERE slug = 'gold_coin');

DELETE FROM public.items WHERE slug = 'gold_coin';

-- 7. Ledger audit: tag currency on transactions + idempotency key
ALTER TABLE public.currency_transactions
    ADD COLUMN IF NOT EXISTS currency_id INT REFERENCES public.currencies(id) ON DELETE SET NULL;
ALTER TABLE public.currency_transactions
    ADD COLUMN IF NOT EXISTS fact_key TEXT UNIQUE;

UPDATE public.currency_transactions ct
SET currency_id = (SELECT id FROM public.currencies WHERE slug = 'gold')
WHERE ct.currency_id IS NULL;
