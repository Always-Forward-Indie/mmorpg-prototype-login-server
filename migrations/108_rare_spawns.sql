-- 108_rare_spawns.sql — bind rare mobs to their common family.
-- SpiritFox/AlphaWolf carry is_rare flags but no spawn logic ever reads
-- them. New rule (rare-as-respawn-replacement): when a common mob of the
-- family is due to respawn, roll rare_spawn_chance_pct — on success the
-- rare template spawns instead, with a rare_mob_spawned announce.
-- rare_spawn_chance values were unitless (8); normalized to percent.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

ALTER TABLE mob ADD COLUMN IF NOT EXISTS rare_of_mob_id integer
  REFERENCES mob(id) ON DELETE SET NULL;

UPDATE mob SET
  rare_of_mob_id = 4,
  rare_spawn_chance = 8,
  rare_spawn_condition = 'on_respawn'
WHERE slug = 'SpiritFox';

UPDATE mob SET
  rare_of_mob_id = 6,
  rare_spawn_chance = 8,
  rare_spawn_condition = 'on_respawn'
WHERE slug = 'AlphaWolf';

COMMENT ON COLUMN public.mob.rare_of_mob_id IS
  'Rare variant of another template: on respawn of the common family mob, roll rare_spawn_chance (percent) to spawn this template instead.';
