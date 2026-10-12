-- 101_titles_fix.sql — unbreak unreachable titles (gamedesign audit 2026-10-03).
-- 5 of 12 titles could never be earned:
--   wolf_hunter / wolf_slayer  -> condition mobSlug 'GreyWolf' does not exist
--                                 (live wolves: ForestWolf, AlphaWolf). Retarget to ForestWolf.
--   goblin_exterminator         -> mobSlug 'ForestGoblin' does not exist, no goblins
--                                 in game. Delete (ON DELETE CASCADE cleans character_titles;
--                                 nobody could earn it, so nothing is lost).
--   bandit_friend               -> requires 'bandits' ally (500) but no mob, quest or
--                                 dialogue grants bandit reputation. Delete.
--   veteran                     -> requires level 25, exp table ends at 10. Lower to 9
--                                 (seasoned_adventurer already sits at 10).
--
-- Applied to DEV via psql; canonical dump updated in the same change.

UPDATE title_definitions
SET condition_params = jsonb_set(condition_params, '{mobSlug}', '"ForestWolf"')
WHERE slug IN ('wolf_hunter', 'wolf_slayer')
  AND condition_params->>'mobSlug' = 'GreyWolf';

DELETE FROM title_definitions WHERE slug = 'goblin_exterminator';
DELETE FROM title_definitions WHERE slug = 'bandit_friend';

UPDATE title_definitions
SET condition_params = jsonb_set(condition_params, '{level}', '9')
WHERE slug = 'veteran'
  AND (condition_params->>'level')::int = 25;

-- Keep the column example in sync (was GreyWolf).
COMMENT ON COLUMN public.title_definitions.condition_params IS 'Data-driven unlock params (JSONB). Fields depend on earn_condition:
     bestiary:   {"mobSlug":"ForestWolf","minTier":6}   — unlocked when bestiary tier >= minTier
     mastery:    {"masterySlug":"sword_mastery","minTier":3} — unlocked when mastery tier >= minTier (1-4)
     reputation: {"factionSlug":"hunters","minTierName":"ally"} — unlocked when faction tier == minTierName
     level:      {"level":10}                          — unlocked on exact level-up
     quest:      {"questSlug":"wolf_hunt_intro"}       — unlocked on quest turn-in';
