-- ============================================================
-- Migration 064: New skills + class restriction at trainers
-- ============================================================
-- Adds:
--   • skill_active_effects table — stores timed buff/heal/dot/hot
--     definitions applied when an active skill is cast.
--   • New skill_damage_types: buff (5), heal (6), teleport_respawn (7)
--   • New skill_damage_formulas: coeff/flat_add for heal type,
--     buff_marker, teleport_marker.
--   • New skills: Battle Cry (Warrior buff), Healing Surge (Mage heal),
--     Blink Home (both classes — teleport to nearest respawn zone).
--   • class_skill_tree entries for each new skill.
--   • skill_active_effects rows for Battle Cry.
--   • Trainer class restriction: npc_trainer_class.class_id is already
--     present; game server now forwards it to chunk server so that
--     buildSkillShopJson / handleRequestLearnSkillEvent can enforce it.
-- ============================================================

-- 1. skill_active_effects -------------------------------------------------
CREATE TABLE IF NOT EXISTS public.skill_active_effects (
    id          SERIAL       PRIMARY KEY,
    skill_id    INTEGER      NOT NULL REFERENCES public.skills(id) ON DELETE CASCADE,
    effect_slug TEXT         NOT NULL,
    effect_type_slug TEXT    NOT NULL,  -- 'buff' | 'debuff' | 'dot' | 'hot'
    attribute_slug TEXT      NOT NULL,
    value       NUMERIC      NOT NULL DEFAULT 0,
    duration_seconds INTEGER NOT NULL DEFAULT 0, -- 0 = permanent (passive only)
    tick_ms     INTEGER      NOT NULL DEFAULT 0  -- 0 = non-tick
);

COMMENT ON TABLE  public.skill_active_effects IS
    'Timed effects applied when an active skill is cast. '
    'Differs from passive_skill_modifiers (always-on) and status effect templates.';
COMMENT ON COLUMN public.skill_active_effects.effect_slug        IS 'Unique slug for this effect instance, e.g. "battle_cry_phys_atk".';
COMMENT ON COLUMN public.skill_active_effects.effect_type_slug   IS '"buff" | "debuff" | "dot" | "hot"';
COMMENT ON COLUMN public.skill_active_effects.attribute_slug     IS 'Which character attribute is modified, e.g. "physical_attack".';
COMMENT ON COLUMN public.skill_active_effects.value              IS 'Magnitude of the effect (flat additive).';
COMMENT ON COLUMN public.skill_active_effects.duration_seconds   IS 'Effect duration in seconds. 0 = permanent.';
COMMENT ON COLUMN public.skill_active_effects.tick_ms            IS 'Tick interval in ms for DoT/HoT. 0 = not periodic.';

-- 2. New skill_damage_types -----------------------------------------------
INSERT INTO public.skill_damage_types (id, slug) VALUES
    (5, 'buff'),
    (6, 'heal'),
    (7, 'teleport_respawn')
ON CONFLICT (id) DO NOTHING;

-- 3. New skill_damage_formulas --------------------------------------------
-- id=4  : 'heal_coeff'      type=heal  — heal scaled by stat coefficient
-- id=5  : 'heal_flat'       type=heal  — heal flat-add amount
-- id=6  : 'buff_marker'     type=buff  — signals skillEffectType='buff'; no damage value
-- id=7  : 'teleport_marker' type=teleport_respawn — signals teleport; no damage value
--
-- NOTE: 'coeff'/'flat_add' slugs are already taken by the damage formulas;
-- get_character_skills matches BOTH ('coeff','heal_coeff') and ('flat_add','heal_flat').
INSERT INTO public.skill_damage_formulas (id, slug, effect_type_id) VALUES
    (4, 'heal_coeff',       6),
    (5, 'heal_flat',        6),
    (6, 'buff_marker',      5),
    (7, 'teleport_marker',  7)
ON CONFLICT (id) DO NOTHING;

-- 4. New skills -----------------------------------------------------------
-- scale_stat_id: 1=PhysAtk, 2=MagAtk
-- school_id:     1=Physical, 2=Magical, 7=Holy
INSERT INTO public.skills OVERRIDING SYSTEM VALUE VALUES
    (13, 'Battle Cry',     'battle_cry',     1, 1, NULL, false),
    (14, 'Healing Surge',  'healing_surge',  2, 7, NULL, false),
    (15, 'Blink Home',     'blink_home',     1, 1, NULL, false)
ON CONFLICT (id) DO NOTHING;

-- 5. skill_effect_instances -----------------------------------------------
-- (id, skill_id, order_idx, target_type_id)
INSERT INTO public.skill_effect_instances (id, skill_id, order_idx, target_type_id) VALUES
    (13, 13, 1, 1),  -- battle_cry    → buff_marker
    (14, 14, 1, 1),  -- healing_surge → heal coeff
    (15, 14, 2, 1),  -- healing_surge → heal flat_add
    (16, 15, 1, 1)   -- blink_home    → teleport_marker
ON CONFLICT (id) DO NOTHING;

-- 6. skill_effects_mapping ------------------------------------------------
-- (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id)
INSERT INTO public.skill_effects_mapping (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id) VALUES
    (21, 13, 6, 0,   1, 0, 0, NULL),  -- battle_cry:    buff_marker  value=0 (no dmg)
    (22, 14, 4, 1.5, 1, 0, 0, NULL),  -- healing_surge: heal_coeff=1.5  (MagAtk × 1.5)
    (23, 15, 5, 80,  1, 0, 0, NULL),  -- healing_surge: heal_flat=80
    (24, 16, 7, 0,   1, 0, 0, NULL)   -- blink_home:    teleport_marker value=0
ON CONFLICT (id) DO NOTHING;

-- 7. skill_properties_mapping ---------------------------------------------
-- property_id: 2=cooldown_ms, 3=gcd_ms, 4=cast_ms, 5=cost_mp,
--              6=max_range,   7=area_radius, 8=swing_ms
--
-- Battle Cry: instant cast, 60 s cd, 30 mp
INSERT INTO public.skill_properties_mapping OVERRIDING SYSTEM VALUE VALUES
    (51, 13, 1, 2, 60000),   -- cooldown_ms = 60 000 ms
    (52, 13, 1, 3,  1500),   -- gcd_ms      =  1 500 ms
    (53, 13, 1, 4,     0),   -- cast_ms     =      0 (instant)
    (54, 13, 1, 5,    30),   -- cost_mp     =     30
    (55, 13, 1, 8,   500),   -- swing_ms    =    500 ms
-- Healing Surge: 2 s cast, 15 s cd, 60 mp
    (56, 14, 1, 2, 15000),   -- cooldown_ms = 15 000 ms
    (57, 14, 1, 3,  1500),   -- gcd_ms      =  1 500 ms
    (58, 14, 1, 4,  2000),   -- cast_ms     =  2 000 ms
    (59, 14, 1, 5,    60),   -- cost_mp     =     60
    (60, 14, 1, 8,   500),   -- swing_ms    =    500 ms
-- Blink Home: 3 s cast (can be interrupted), 120 s cd, 20 mp
    (61, 15, 1, 2, 120000),  -- cooldown_ms = 120 000 ms
    (62, 15, 1, 3,   1500),  -- gcd_ms      =   1 500 ms
    (63, 15, 1, 4,   3000),  -- cast_ms     =   3 000 ms
    (64, 15, 1, 5,     20),  -- cost_mp     =      20
    (65, 15, 1, 8,    500)   -- swing_ms    =    500 ms
ON CONFLICT (id) DO NOTHING;

-- 8. class_skill_tree entries ---------------------------------------------
-- class_id: 1=Mage, 2=Warrior
-- (class_id, skill_id, required_level, is_default, prereq_skill_id,
--  skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)

-- Battle Cry → Warrior only, lvl 5
INSERT INTO public.class_skill_tree
    (class_id, skill_id, required_level, is_default, prerequisite_skill_id,
     skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES (2, 13, 5, false, NULL, 1, 100, 1, false, NULL);

-- Healing Surge → Mage only, lvl 8
INSERT INTO public.class_skill_tree
    (class_id, skill_id, required_level, is_default, prerequisite_skill_id,
     skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES (1, 14, 8, false, NULL, 1, 150, 1, false, NULL);

-- Blink Home → both classes, lvl 5
INSERT INTO public.class_skill_tree
    (class_id, skill_id, required_level, is_default, prerequisite_skill_id,
     skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES (1, 15, 5, false, NULL, 1, 80, 1, false, NULL);

INSERT INTO public.class_skill_tree
    (class_id, skill_id, required_level, is_default, prerequisite_skill_id,
     skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES (2, 15, 5, false, NULL, 1, 80, 1, false, NULL);

-- 9. skill_active_effects data --------------------------------------------
-- Battle Cry: +25 physical_attack for 30 seconds
INSERT INTO public.skill_active_effects
    (skill_id, effect_slug, effect_type_slug, attribute_slug, value, duration_seconds, tick_ms)
VALUES (13, 'battle_cry_phys_atk', 'buff', 'physical_attack', 25, 30, 0);

-- 10. Bump sequences to avoid future conflicts ----------------------------
SELECT setval('public.skill_effects_type_id_seq', (SELECT MAX(id) FROM public.skill_damage_types));
SELECT setval('public.skill_effects_id_seq',      (SELECT MAX(id) FROM public.skill_damage_formulas));
