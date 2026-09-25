-- 092_beast_flee_thresholds.sql
-- Small beasts flee below 30% HP (flee behavior + archetypes were parsed
-- but lost in copies until the propagate fix; DB values stayed 0 = never).
-- Big/boss mobs (bears, alpha, skeletons, golems) stand their ground (0).
UPDATE public.mob SET flee_hp_threshold = 0.3 WHERE slug IN ('ForestBoar', 'ForestFox', 'ForestWolf', 'SpiritFox');
