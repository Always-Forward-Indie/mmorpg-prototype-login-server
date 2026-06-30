-- 080_mob_balance_reputation_bosses.sql
-- 1. Bear + Golem stat balance
-- 2. NPC faction_slug assignment
-- 3. Mob faction_slug + rep_delta_per_kill
-- 4. Timed champion bosses (ancient_bear, awakened_golem)

-- ── 1. Balance Bear (id=9) ──────────────────────────────────────────────────
-- Reduce aggro range, attack range, and physical_attack for a fair solo challenge.
UPDATE public.mob SET aggro_range = 600, attack_range = 140 WHERE id = 9;
UPDATE public.mob_stat SET flat_value = 35.00 WHERE mob_id = 9 AND attribute_id = 12;

-- ── 2. Balance Golem (id=10) ─────────────────────────────────────────────────
-- Reduce stats to duo-boss level: less HP, less damage, shorter range.
UPDATE public.mob SET aggro_range = 500, attack_range = 160, spawn_health = 3000 WHERE id = 10;
UPDATE public.mob_stat SET flat_value = 3000.00 WHERE mob_id = 10 AND attribute_id = 1;
UPDATE public.mob_stat SET flat_value = 40.00  WHERE mob_id = 10 AND attribute_id = 12;

-- ── 3. NPC faction_slug assignment ───────────────────────────────────────────
UPDATE public.npc SET faction_slug = 'hunters'    WHERE slug = 'edrik';
UPDATE public.npc SET faction_slug = 'merchants'  WHERE slug = 'sylara';
UPDATE public.npc SET faction_slug = 'city_guard' WHERE slug = 'theron';

-- ── 4. Mob faction_slug + rep_delta_per_kill ─────────────────────────────────
-- Rare/boss mobs grant small reputation; ordinary mobs grant none.
UPDATE public.mob SET faction_slug = 'hunters',    rep_delta_per_kill = 5  WHERE id = 7;  -- Alpha Wolf
UPDATE public.mob SET faction_slug = 'nature',     rep_delta_per_kill = 5  WHERE id = 8;  -- Spirit Fox
UPDATE public.mob SET faction_slug = 'hunters',    rep_delta_per_kill = 10 WHERE id = 9;  -- Bear
UPDATE public.mob SET faction_slug = 'city_guard', rep_delta_per_kill = 10 WHERE id = 10; -- Golem

-- ── 5. Timed champion: Ancient Bear (id=11) ──────────────────────────────────
-- Spawns in the Forest zone (id=3) every 4 hours, lives 30 min.
INSERT INTO public.mob (id, name, race_id, "level", spawn_health, spawn_mana, is_aggressive, slug, radius, base_xp, rank_id, aggro_range, attack_range, attack_cooldown, chase_multiplier, patrol_speed, is_social, chase_duration, flee_hp_threshold, ai_archetype, can_evolve, is_rare, rare_spawn_chance, rare_spawn_condition, faction_slug, rep_delta_per_kill, biome_slug, mob_type_slug, patrol_radius)
OVERRIDING SYSTEM VALUE
VALUES (11, 'Древний медведь', 2, 12, 3500, 60, TRUE, 'AncientBear', 250, 1500, 6, 700, 160, 2.5, 0.9, 0.5, FALSE, 15, 0, 'melee', FALSE, FALSE, 0, NULL, 'hunters', 25, '', 'beast', 600);

INSERT INTO public.mob_stat (id, mob_id, attribute_id, flat_value, multiplier, exponent)
OVERRIDING SYSTEM VALUE VALUES
(424, 11, 1,  3500.00, NULL, NULL),
(425, 11, 2,  60.00,   NULL, NULL),
(426, 11, 3,  30.00,   NULL, NULL),
(427, 11, 4,  3.00,    NULL, NULL),
(428, 11, 6,  30.00,   NULL, NULL),
(429, 11, 7,  12.00,   NULL, NULL),
(430, 11, 8,  10.00,   NULL, NULL),
(431, 11, 9,  200.00,  NULL, NULL),
(432, 11, 10, 4.00,    NULL, NULL),
(433, 11, 11, 0.00,    NULL, NULL),
(434, 11, 12, 55.00,   NULL, NULL),
(435, 11, 13, 0.00,    NULL, NULL),
(436, 11, 14, 12.00,   NULL, NULL),
(437, 11, 15, 3.00,    NULL, NULL),
(438, 11, 16, 0.00,    NULL, NULL),
(439, 11, 17, 0.00,    NULL, NULL),
(440, 11, 18, 3.50,    NULL, NULL),
(441, 11, 19, 4.00,    NULL, NULL),
(442, 11, 20, 0.00,    NULL, NULL),
(443, 11, 27, 25.00,   NULL, NULL),
(444, 11, 28, 2.00,    NULL, NULL),
(445, 11, 29, 3.00,    NULL, NULL),
(446, 11, 30, 0.00,    NULL, NULL),
(447, 11, 31, 0.00,    NULL, NULL),
(448, 11, 32, 0.00,    NULL, NULL),
(449, 11, 33, 0.00,    NULL, NULL),
(450, 11, 34, 0.00,    NULL, NULL),
(451, 11, 35, 0.00,    NULL, NULL);

INSERT INTO public.mob_skills (mob_id, skill_id, current_level)
VALUES (11, 1, 1);

INSERT INTO public.timed_champion_templates (slug, zone_id, mob_template_id, interval_hours, window_minutes, announcement_key)
VALUES ('ancient_bear', 7, 11, 4, 30, 'champion.ancient_bear');

-- ── 6. Timed champion: Awakened Golem (id=12) ────────────────────────────────
-- Spawns in the Ruins zone (id=2) every 6 hours, lives 45 min.
INSERT INTO public.mob (id, name, race_id, "level", spawn_health, spawn_mana, is_aggressive, slug, radius, base_xp, rank_id, aggro_range, attack_range, attack_cooldown, chase_multiplier, patrol_speed, is_social, chase_duration, flee_hp_threshold, ai_archetype, can_evolve, is_rare, rare_spawn_chance, rare_spawn_condition, faction_slug, rep_delta_per_kill, biome_slug, mob_type_slug, patrol_radius)
OVERRIDING SYSTEM VALUE
VALUES (12, 'Пробуждённый голем', 2, 18, 8000, 300, TRUE, 'AwakenedGolem', 300, 3500, 6, 600, 220, 3.5, 1.0, 0.3, FALSE, 20, 0, 'melee', FALSE, FALSE, 0, NULL, 'city_guard', 25, '', 'elemental', 400);

INSERT INTO public.mob_stat (id, mob_id, attribute_id, flat_value, multiplier, exponent)
OVERRIDING SYSTEM VALUE VALUES
(452, 12, 1,  8000.00, NULL, NULL),
(453, 12, 2,  300.00,  NULL, NULL),
(454, 12, 3,  40.00,   NULL, NULL),
(455, 12, 4,  8.00,    NULL, NULL),
(456, 12, 6,  50.00,   NULL, NULL),
(457, 12, 7,  40.00,   NULL, NULL),
(458, 12, 8,  3.00,    NULL, NULL),
(459, 12, 9,  200.00,  NULL, NULL),
(460, 12, 10, 3.00,    NULL, NULL),
(461, 12, 11, 2.00,    NULL, NULL),
(462, 12, 12, 65.00,   NULL, NULL),
(463, 12, 13, 15.00,   NULL, NULL),
(464, 12, 14, 10.00,   NULL, NULL),
(465, 12, 15, 1.00,    NULL, NULL),
(466, 12, 16, 0.00,    NULL, NULL),
(467, 12, 17, 0.00,    NULL, NULL),
(468, 12, 18, 2.50,    NULL, NULL),
(469, 12, 19, 3.00,    NULL, NULL),
(470, 12, 20, 0.00,    NULL, NULL),
(471, 12, 27, 35.00,   NULL, NULL),
(472, 12, 28, 5.00,    NULL, NULL),
(473, 12, 29, 1.00,    NULL, NULL),
(474, 12, 30, 0.00,    NULL, NULL),
(475, 12, 31, 0.00,    NULL, NULL),
(476, 12, 32, 0.00,    NULL, NULL),
(477, 12, 33, 0.00,    NULL, NULL),
(478, 12, 34, 0.00,    NULL, NULL),
(479, 12, 35, 0.00,    NULL, NULL);

INSERT INTO public.mob_skills (mob_id, skill_id, current_level)
VALUES (12, 1, 1);

INSERT INTO public.timed_champion_templates (slug, zone_id, mob_template_id, interval_hours, window_minutes, announcement_key)
VALUES ('awakened_golem', 6, 12, 6, 45, 'champion.awakened_golem');
