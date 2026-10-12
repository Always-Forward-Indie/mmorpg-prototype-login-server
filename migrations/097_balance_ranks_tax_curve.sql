-- 097_balance_ranks_tax_curve.sql — balance pass (lab-driven, see
-- integration-tests/balance/report.md).
--
-- 1. Open-world bears/golems out of boss rank: rank = party size
--    (normal/pack/strong = solo, elite 2.2 = duo, miniboss 5.0 = group,
--    boss 20.0 = raid). Only AwakenedGolem stays a true boss.
--    Solo TTK was 700-1600s even at-level; after: ~40s solo / ~20s duo
--    (elite), ~100s solo (miniboss).
-- 2. Economy sinks: 5% sell tax + 5% buy markup (were 0.0/0.0 = pure
--    faucet). Config-only, one-line revert.
-- 3. XP curve 3-6 softened x2.0 -> ~x1.5 (L4->5 grind wall 44 kills -> ~25),
--    L10 total kept (~52k vs 60k). Duplicate exp_for_level rows removed
--    (every level was stored twice; DISTINCT kept first).
--
-- Applied to DEV via psql; canonical dump updated in the same change.

-- 1. Ranks.
UPDATE mob SET rank_id = 4 WHERE slug = 'ForestBear';    -- elite 2.2
UPDATE mob SET rank_id = 4 WHERE slug = 'AncientBear';   -- elite 2.2
UPDATE mob SET rank_id = 5 WHERE slug = 'StoneGolem';    -- miniboss 5.0
-- AwakenedGolem stays rank 6 (boss 20.0, raid target).

-- 2. Economy sinks.
UPDATE game_config SET value = '0.05', updated_at = NOW()
  WHERE key = 'economy.vendor_sell_tax_pct';
UPDATE game_config SET value = '0.05', updated_at = NOW()
  WHERE key = 'economy.vendor_buy_markup_pct';

-- 3. XP curve (idempotent re-seed; id is GENERATED ALWAYS).
DELETE FROM exp_for_level;
INSERT INTO exp_for_level (id, level, experience_points) OVERRIDING SYSTEM VALUE VALUES
  (1, 1, 100),
  (2, 2, 500),
  (3, 3, 1000),
  (4, 4, 1500),
  (5, 5, 2500),
  (6, 6, 4500),
  (7, 7, 9000),
  (8, 8, 16000),
  (9, 9, 28000),
  (10, 10, 52000);
SELECT setval('exp_for_level_id_seq', (SELECT MAX(id) FROM exp_for_level));
