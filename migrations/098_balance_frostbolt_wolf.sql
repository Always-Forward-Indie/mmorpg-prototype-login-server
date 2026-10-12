-- 098_balance_frostbolt_wolf.sql — micro-tuning (lab-driven, see
-- integration-tests/balance/report.md).
--
-- 1. frost_bolt required_level 5 -> 3 (Mage only). Mage L1-4 weapon was the
--    physical stick (basic_attack scales physical_attack): mage lost to
--    same-level mobs. A weak early bolt (1.6/20, 7s cd, 35 MP) gives fair
--    play without breaking anything (small numbers, expensive mana).
-- 2. ForestWolf physical_attack 15 -> 17 (+13%). Fair mobs barely scratched
--    geared warriors (83% HP left); light pressure makes potions matter.
--    Bosses untouched.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

UPDATE class_skill_tree SET required_level = 3
  WHERE class_id = 1
    AND skill_id = (SELECT id FROM skills WHERE slug = 'frost_bolt');

UPDATE mob_stat SET flat_value = 17
  WHERE mob_id = 6 AND attribute_id = 12;
