-- 105_config_cleanup.sql — every key works or goes (AAA rule).
-- DELETE orphans (no reader, live system lives elsewhere):
--   aggro.base_radius/leash_distance : per-mob aggroRange + timer leash are live
--   exploration.default_xp_reward     : zones.exploration_xp_reward col default 100 is live
--   zone_event.pre_announce_sec       : no announce mechanism (champions have their own key)
--   combat.elemental_resistance_cap   : covered by combat.max_resistance_cap for all schools
-- ADD keys the code already reads with fallbacks (no behavior change today,
-- tunability tomorrow): champion.*, survival_champion.*, scheduler.character_*.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

DELETE FROM game_config WHERE key IN
  ('aggro.base_radius',
   'aggro.leash_distance',
   'exploration.default_xp_reward',
   'zone_event.pre_announce_sec',
   'combat.elemental_resistance_cap');

INSERT INTO game_config (key, value, value_type, description) VALUES
  ('champion.pre_announce_sec', '300', 'int', 'Timed champion pre-announce window'),
  ('champion.hp_multiplier', '3.0', 'float', 'Champion HP multiplier'),
  ('champion.damage_multiplier', '1.5', 'float', 'Champion damage multiplier'),
  ('champion.despawn_minutes', '30', 'int', 'Champion despawn window default'),
  ('champion.spawn_chance_pct', '100', 'float', 'Champion spawn chance default'),
  ('champion.max_active_per_zone', '3', 'int', 'Max active champions per zone'),
  ('survival_champion.evolve_hours', '12', 'int', 'Survival evolution period'),
  ('survival_champion.hp_bonus_pct', '0.5', 'float', 'Survival evolve HP bonus'),
  ('scheduler.character_stale_threshold_ms', '180000', 'int', 'Stale character sweep threshold')
ON CONFLICT (key) DO NOTHING;
