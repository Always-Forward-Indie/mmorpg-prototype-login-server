-- 106_survival_evolution.sql — enable survival evolution content.
-- The tick (scheduler.survival_evo_ms, 5 min) runs but no mob has
-- can_evolve set, so nothing can ever evolve. Enable for two long-lived
-- predators: a wolf/bear that survives 12h becomes a champion (+50% HP,
-- loot x1.3, survival_evolved announce). Pure content change.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

UPDATE mob SET can_evolve = TRUE WHERE slug IN ('AlphaWolf', 'ForestBear');
