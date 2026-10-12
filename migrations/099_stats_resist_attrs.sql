-- 099_stats_resist_attrs.sql — stat revival foundation (no behavior change).
--
-- Adds physical_resistance / magical_resistance attributes (ids 36/37) with
-- zero base formulas for both classes. Combat already looks up
-- {school}_resistance generically, so the pipeline works the moment gear or
-- passives grant these — today everything stays 0 (verified: no item or
-- passive references the new slugs yet).
--
-- Applied to DEV via psql; canonical dump updated in the same change.

INSERT INTO entity_attributes (id, name, slug, is_percentage)
OVERRIDING SYSTEM VALUE VALUES
  (36, 'Physical Resistance', 'physical_resistance', TRUE),
  (37, 'Magical Resistance', 'magical_resistance', TRUE)
ON CONFLICT (id) DO NOTHING;

-- Zero-base formulas: attribute exists, contributes nothing until granted.
INSERT INTO class_stat_formula (class_id, attribute_id, base_value, multiplier, exponent)
VALUES
  (1, 36, 0, 0, 1.0),
  (1, 37, 0, 0, 1.0),
  (2, 36, 0, 0, 1.0),
  (2, 37, 0, 0, 1.0)
ON CONFLICT DO NOTHING;
