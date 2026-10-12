-- 104_reputation_config.sql — wire reputation balance into game_config (AAA rule).
-- The chunk code reads reputation.vendor_discount_threshold + pct (fallbacks
-- 200/0.05) but those keys never existed in game_config — tuning was dead.
-- Meanwhile reputation.vendor_buy_discount/sell_bonus existed but no code
-- ever read them. Fix: add the keys the code reads, drop the orphans.
-- Tier thresholds (enemy/neutral/friendly/ally) already exist and are now
-- fed to ReputationManager::setThresholds on catalog sync.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

INSERT INTO game_config (key, value, value_type, description) VALUES
  ('reputation.vendor_discount_threshold', '200', 'int',
   'Rep needed for vendor discount (VendorEventHandler)'),
  ('reputation.vendor_discount_pct', '0.05', 'float',
   'Vendor buy/sell discount at threshold (VendorDiscountPolicy)')
ON CONFLICT (key) DO NOTHING;

DELETE FROM game_config WHERE key IN
  ('reputation.vendor_buy_discount', 'reputation.vendor_sell_bonus');
