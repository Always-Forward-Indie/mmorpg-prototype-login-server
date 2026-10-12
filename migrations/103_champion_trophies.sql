-- 103_champion_trophies.sql — guaranteed champion trophies (gamedesign audit).
-- Loot is winner-takes-all (30s killer reservation), so champion runs feel
-- unrewarding for everyone but the last hit. Fix without new mechanics:
-- every champion kill drops a type-logical trophy (drop_chance 1.00) that
-- vendor 1 buys back; the gold buys gear at vendor 2. Pure content change.
--
-- Trophy by mob type (fang for beasts, heart/core for elementals):
--   AncientBear  (beast, elite 12)  -> alpha_fang,        sell 200 (rare)
--   AwakenedGolem (elemental, boss 18) -> golem_heart,     sell 500 (epic)
-- The dev fox (mob 4, DEV arena) is SKIPPED on purpose: it shares its
-- template with ordinary level-1 foxes, so a guaranteed trophy would flood
-- the starter economy with 10g drops.
--
-- Prices anchored to live content: materials sell for 1-5, mid gear costs
-- 400-600, tomes 400-1200. One bear trophy ~ half a mid sword; one golem
-- heart ~ half a tome.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

INSERT INTO items (name, slug, description, item_type, weight, rarity_id, stack_max,
                   is_durable, is_tradable, vendor_price_buy, vendor_price_sell,
                   level_requirement, is_equippable, is_harvest)
VALUES
  ('Клык вожака', 'alpha_fang', 'Трофей с древнего медведя. Скупщики платят хорошо.',
   6, 0.3, 3, 64, FALSE, TRUE, 400, 200, 0, FALSE, FALSE),
  ('Сердце голема', 'golem_heart', 'Пульсирующее ядро пробуждённого голема. Тяжёлое и дорогое.',
   6, 2.0, 4, 64, FALSE, TRUE, 1000, 500, 0, FALSE, FALSE);

INSERT INTO mob_loot_info (mob_id, item_id, drop_chance, is_harvest_only,
                           min_quantity, max_quantity, loot_tier)
VALUES
  (11, (SELECT id FROM items WHERE slug = 'alpha_fang'), 1.00, FALSE, 1, 1, 'rare'),
  (12, (SELECT id FROM items WHERE slug = 'golem_heart'), 1.00, FALSE, 1, 1, 'very_rare');
