-- Migration 041: Weapon mastery slugs, quest reputation fields, 3-tier durability config
-- Applied: 2026-04-16

BEGIN;

-- =========================================================================
-- 1. Wire mastery_slug to existing weapon items
-- =========================================================================

UPDATE items SET mastery_slug = 'sword_mastery' WHERE slug = 'iron_sworld';
UPDATE items SET mastery_slug = 'staff_mastery' WHERE slug = 'wooden_staff';

-- =========================================================================
-- 2. Quest reputation columns
-- =========================================================================

ALTER TABLE quest
    ADD COLUMN IF NOT EXISTS reputation_faction_slug VARCHAR(64) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reputation_on_complete  INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS reputation_on_fail      INT NOT NULL DEFAULT 0;

-- =========================================================================
-- 3. Replace flat durability penalty config with 3-tier config
-- =========================================================================

DELETE FROM game_config
WHERE key IN (
    'durability.warning_threshold_pct',
    'durability.warning_penalty_pct'
);

-- Tier 1: 75% → small penalty (-5%)
INSERT INTO game_config (key, value) VALUES
    ('durability.tier1_threshold_pct', '0.75'),
    ('durability.tier1_penalty_pct',   '0.05');

-- Tier 2: 50% → moderate penalty (-15%)
INSERT INTO game_config (key, value) VALUES
    ('durability.tier2_threshold_pct', '0.50'),
    ('durability.tier2_penalty_pct',   '0.15');

-- Tier 3: 25% → severe penalty (-30%)
INSERT INTO game_config (key, value) VALUES
    ('durability.tier3_threshold_pct', '0.25'),
    ('durability.tier3_penalty_pct',   '0.30');

COMMIT;
