-- 111_currency_loot.sql — gold drops as wallet credit (auto-loot, WoW-style).
-- Replaces the deleted gold_coin rows in mob_loot_info (see 110).
-- LootManager rolls this table on kill and credits character_currencies
-- directly; no world pickup, no item rows.

CREATE TABLE IF NOT EXISTS public.mob_currency_loot (
    id SERIAL PRIMARY KEY,
    mob_id INT NOT NULL,
    currency_id INT NOT NULL REFERENCES public.currencies(id) ON DELETE CASCADE,
    drop_chance NUMERIC(5,2) NOT NULL DEFAULT 0.00 CHECK (drop_chance >= 0 AND drop_chance <= 1),
    min_quantity SMALLINT NOT NULL DEFAULT 1 CHECK (min_quantity >= 1),
    max_quantity SMALLINT NOT NULL DEFAULT 1 CHECK (max_quantity >= min_quantity),
    UNIQUE (mob_id, currency_id)
);
COMMENT ON TABLE public.mob_currency_loot IS 'Валютный лут: автокредит в кошелёк при убийстве, без подбора с земли.';

-- Restored baseline drops (were mob_loot_info item_id=16):
-- mob 5 Skeleton 20% 1-2g, mob 10 Stone Golem 100% 2-5g.
INSERT INTO public.mob_currency_loot (mob_id, currency_id, drop_chance, min_quantity, max_quantity)
SELECT 5, id, 0.20, 1, 2 FROM public.currencies WHERE slug = 'gold'
ON CONFLICT (mob_id, currency_id) DO UPDATE
SET drop_chance = EXCLUDED.drop_chance,
    min_quantity = EXCLUDED.min_quantity,
    max_quantity = EXCLUDED.max_quantity;

INSERT INTO public.mob_currency_loot (mob_id, currency_id, drop_chance, min_quantity, max_quantity)
SELECT 10, id, 1.00, 2, 5 FROM public.currencies WHERE slug = 'gold'
ON CONFLICT (mob_id, currency_id) DO UPDATE
SET drop_chance = EXCLUDED.drop_chance,
    min_quantity = EXCLUDED.min_quantity,
    max_quantity = EXCLUDED.max_quantity;
