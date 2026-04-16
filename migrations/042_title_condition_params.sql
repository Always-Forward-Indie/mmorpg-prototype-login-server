-- Migration 042: Data-driven title auto-grant system
-- Adds condition_params JSONB column to title_definitions and seeds real titles.
-- earn_condition now drives automatic granting via checkAndGrantTitles() on chunk-server.

BEGIN;

-- =========================================================================
-- 1. Add condition_params JSONB column
-- =========================================================================

ALTER TABLE title_definitions
    ADD COLUMN IF NOT EXISTS condition_params JSONB NOT NULL DEFAULT '{}';

COMMENT ON COLUMN title_definitions.condition_params IS
    'Data-driven unlock params (JSONB). Fields depend on earn_condition:
     bestiary:   {"mobSlug":"GreyWolf","minTier":6}   — unlocked when bestiary tier >= minTier
     mastery:    {"masterySlug":"sword_mastery","minTier":3} — unlocked when mastery tier >= minTier (1-4)
     reputation: {"factionSlug":"hunters","minTierName":"ally"} — unlocked when faction tier == minTierName
     level:      {"level":10}                          — unlocked on exact level-up
     quest:      {"questSlug":"wolf_hunt_intro"}       — unlocked on quest turn-in';

-- =========================================================================
-- 2. Replace placeholder titles with real data-driven titles
-- =========================================================================

DELETE FROM title_definitions WHERE id IN (1, 2, 3, 4);

-- Reset sequence so new IDs start from 1
SELECT setval('title_definitions_id_seq', 1, false);

-- ---- Bestiary titles ----
INSERT INTO title_definitions (slug, display_name, description, earn_condition, condition_params, bonuses) VALUES
(
    'wolf_slayer',
    'Волкобой',
    'Достиг максимального тира бестиария серого волка. Волки тебя не пугают.',
    'bestiary',
    '{"mobSlug": "GreyWolf", "minTier": 6}',
    '[{"attributeSlug": "physical_attack", "value": 2.0}, {"attributeSlug": "move_speed", "value": 1.0}]'
),
(
    'wolf_hunter',
    'Охотник на волков',
    'Достиг 3-го тира бестиария серого волка. Ты знаешь их повадки.',
    'bestiary',
    '{"mobSlug": "GreyWolf", "minTier": 3}',
    '[{"attributeSlug": "physical_attack", "value": 1.0}]'
),
(
    'goblin_exterminator',
    'Истребитель гоблинов',
    'Достиг 4-го тира бестиария лесного гоблина. Гоблины боятся тебя.',
    'bestiary',
    '{"mobSlug": "ForestGoblin", "minTier": 4}',
    '[{"attributeSlug": "physical_attack", "value": 1.5}, {"attributeSlug": "physical_defense", "value": 1.0}]'
),

-- ---- Mastery titles ----
(
    'swordsman',
    'Мечник',
    'Достиг 3-го тира мастерства меча. Клинок — твоё продолжение.',
    'mastery',
    '{"masterySlug": "sword_mastery", "minTier": 3}',
    '[{"attributeSlug": "physical_attack", "value": 3.0}, {"attributeSlug": "crit_chance", "value": 0.5}]'
),
(
    'archmage',
    'Архимаг',
    'Достиг 4-го тира мастерства посоха. Магия послушна тебе.',
    'mastery',
    '{"masterySlug": "staff_mastery", "minTier": 4}',
    '[{"attributeSlug": "magic_attack", "value": 5.0}]'
),
(
    'bowmaster',
    'Мастер лука',
    'Достиг 3-го тира мастерства лука. Стрелы не знают промаха.',
    'mastery',
    '{"masterySlug": "bow_mastery", "minTier": 3}',
    '[{"attributeSlug": "crit_chance", "value": 1.0}, {"attributeSlug": "physical_attack", "value": 2.0}]'
),

-- ---- Reputation titles ----
(
    'friend_of_hunters',
    'Союзник Гильдии Охотников',
    'Достиг статуса союзника в Гильдии Охотников.',
    'reputation',
    '{"factionSlug": "hunters", "minTierName": "ally"}',
    '[{"attributeSlug": "move_speed", "value": 2.0}, {"attributeSlug": "physical_attack", "value": 1.0}]'
),
(
    'city_guardian',
    'Страж Города',
    'Достиг статуса союзника в Городской Страже.',
    'reputation',
    '{"factionSlug": "city_guard", "minTierName": "ally"}',
    '[{"attributeSlug": "physical_defense", "value": 3.0}, {"attributeSlug": "max_health", "value": 15.0}]'
),
(
    'bandit_friend',
    'Свой среди чужих',
    'Достиг статуса союзника в Братстве Бандитов.',
    'reputation',
    '{"factionSlug": "bandits", "minTierName": "ally"}',
    '[{"attributeSlug": "move_speed", "value": 3.0}]'
),

-- ---- Level titles ----
(
    'seasoned_adventurer',
    'Бывалый искатель приключений',
    'Достиг 10-го уровня. Путь только начинается.',
    'level',
    '{"level": 10}',
    '[{"attributeSlug": "max_health", "value": 10.0}]'
),
(
    'veteran',
    'Ветеран',
    'Достиг 25-го уровня. Опыт не купить за золото.',
    'level',
    '{"level": 25}',
    '[{"attributeSlug": "physical_defense", "value": 5.0}, {"attributeSlug": "max_health", "value": 20.0}]'
),

-- ---- Quest titles ----
(
    'first_hunter',
    'Первая охота',
    'Завершил вводное задание по охоте на волков.',
    'quest',
    '{"questSlug": "wolf_hunt_intro"}',
    '[{"attributeSlug": "physical_attack", "value": 1.0}]'
);

COMMIT;
