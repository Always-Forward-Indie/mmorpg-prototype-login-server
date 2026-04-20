-- Migration 067: skill cooldown persistence
-- Stores active skill cooldowns per character so that they survive reconnects/restarts.
-- The row is upserted each time a skill is used and pruned by the game server on load.

CREATE TABLE IF NOT EXISTS player_skill_cooldown (
    character_id  INT          NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    skill_slug    VARCHAR(100) NOT NULL,
    cooldown_ends_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (character_id, skill_slug)
);

CREATE INDEX IF NOT EXISTS ix_psc_char
    ON player_skill_cooldown (character_id);

COMMENT ON TABLE player_skill_cooldown IS
    'Per-character active skill cooldowns. Upserted every time a skill is used; '
    'expired rows cleaned up when the character''s cooldowns are loaded on join.';
