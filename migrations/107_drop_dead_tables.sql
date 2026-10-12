-- 107_drop_dead_tables.sql — remove tables no code ever touches.
-- mob_position: spawn goes through spawn_zone_mobs; zero reads/writes.
-- mob_active_effect: mob effects live in MobInstanceManager memory and die
--   with the instance; zero reads/writes.
-- Both empty; no inbound FKs. db.sh PLAYER_TABLES cleanup goes with it.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

DROP TABLE IF EXISTS mob_position;
DROP TABLE IF EXISTS mob_active_effect;
