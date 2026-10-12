-- 102_remove_bandits.sql — drop the dead bandits faction (gamedesign audit 2026-10-03).
-- The faction has no income source anywhere: no mob, NPC, quest or dialogue
-- grants bandit reputation (verified). The only rows are two orphaned
-- character_reputation leftovers on fixture bots (chars 10/14, stale values
-- from an era when something granted it) plus reliability-contract traffic
-- (factkey/outbox/crash tests use it as a mechanic-free channel — repointed
-- to merchants in the same change).
--
-- Order matters (FK character_reputation.faction_slug -> factions.slug).
-- Player tables are stripped from the canonical dump, so this is dump-safe.
--
-- Applied to DEV via psql; canonical dump updated in the same change.

DELETE FROM character_reputation WHERE faction_slug = 'bandits';
DELETE FROM factions WHERE slug = 'bandits';
