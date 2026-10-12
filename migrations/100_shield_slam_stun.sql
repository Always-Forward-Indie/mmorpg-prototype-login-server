-- 100_shield_slam_stun.sql — first CC skill (stun 2s) proving the CC+DR
-- pipeline end to end (initiation gates, DR, mob hold, expiry).
-- Warrior L5, damage + 2s stun, 12s cd. No existing rows touched.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

INSERT INTO skills (id, name, slug, scale_stat_id, school_id, animation_name, is_passive)
OVERRIDING SYSTEM VALUE VALUES
  (17, 'Shield Slam', 'shield_slam', 1, 1, NULL, FALSE);

INSERT INTO skill_effect_instances (id, skill_id, order_idx, target_type_id)
OVERRIDING SYSTEM VALUE VALUES
  (18, 17, 1, 1);

INSERT INTO skill_effects_mapping (effect_instance_id, effect_id, value, level, tick_ms, duration_ms)
VALUES
  (18, 1, 1.2, 1, 0, 0),
  (18, 2, 10, 1, 0, 0);

INSERT INTO skill_active_effects
  (skill_id, effect_slug, effect_type_slug, attribute_slug, value, duration_seconds, tick_ms)
VALUES
  (17, 'shield_slam_stun', 'stun', '', 0, 2, 0);

INSERT INTO class_skill_tree
  (class_id, skill_id, required_level, is_default, prerequisite_skill_id,
   skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES
  (2, 17, 5, FALSE, NULL, 1, 100, 1, FALSE, NULL);

-- Repair drifted identity sequence (was behind max(id); plain INSERTs fail).
SELECT setval('skills_attributes_mapping_id_seq',
              (SELECT MAX(id) FROM skill_properties_mapping));

INSERT INTO skill_properties_mapping (skill_id, skill_level, property_id, property_value)
VALUES
  (17, 1, 2, 12000),
  (17, 1, 3, 1000),
  (17, 1, 4, 0),
  (17, 1, 5, 0),
  (17, 1, 6, 2.5),
  (17, 1, 8, 300);
