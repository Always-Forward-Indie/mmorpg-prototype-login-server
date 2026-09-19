-- ============================================================================
-- DEV-ONLY test content: learn-success fixture (bot_08 / 'Bot H').
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_learn.sql
-- Then: pytest Tests/Contract/test_reg_learn.py -q -k success
-- No server restart needed (level/SP/skills load on character join).
--
-- What: boosts 'Bot H' (stable name across reseeds; bot_08, kill-swarm bot
-- whose tests are level-agnostic) to level 5 + 5 SP, and clears any prior
-- power_slash learn so the success path is repeatable. Bot H holds ~10k
-- gold, covering the 100g fee. Guards test (bot_01, level 3) is untouched.
-- Idempotent: re-runnable (UPDATE + DELETE by name/slug, no inserts).
-- ============================================================================

BEGIN;

-- Boost Bot H to level 5 (power_slash requires 5; exp_for_level: 4000).
UPDATE characters
SET level = 5, experience_points = 4000, free_skill_points = 5
WHERE name = 'Bot H';

-- Clear prior learn for repeatability (fresh success path every run).
DELETE FROM character_skills
WHERE character_id = (SELECT id FROM characters WHERE name = 'Bot H')
  AND skill_id = (SELECT id FROM skills WHERE slug = 'power_slash');

COMMIT;

-- Verification (expect level 5, SP 5, no power_slash row).
SELECT name, level, experience_points, free_skill_points
FROM characters WHERE name = 'Bot H';
SELECT s.slug FROM character_skills cs
JOIN skills s ON s.id = cs.skill_id
JOIN characters c ON c.id = cs.character_id
WHERE c.name = 'Bot H';
