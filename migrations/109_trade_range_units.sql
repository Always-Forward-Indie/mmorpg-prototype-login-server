-- 109_trade_range_units.sql — fix P2P trade distance unit mismatch.
-- economy.trade_range was 5.0 while every distance on the wire is checked in
-- world units (100 units = 1 m, see DistanceUtils::kRangeUnitScale).
-- VendorEventHandler compares trade_range directly against unit positions,
-- so 5.0 units (~5 cm, ~10x less than nose-to-nose ~53 u) rejected every
-- trade with out_of_range. Player skills already convert meters -> units
-- (SkillSystem::metersToUnits); trade_range is documented as units, so the
-- value itself moves to 500 (= 5 m), consistent with NPC radius ~100,
-- mob attack_range 110-220, aggro 500-800 and ambient triggers ~400.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

UPDATE game_config SET value = '500.0', updated_at = NOW(),
  description = 'Max distance (world units; 100 units = 1 m, so 500 = 5 m) between two players for P2P trade to start.'
  WHERE key = 'economy.trade_range';
