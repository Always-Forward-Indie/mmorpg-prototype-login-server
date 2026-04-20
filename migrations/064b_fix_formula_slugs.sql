-- ============================================================
-- Migration 064b: Fix partial application of 064
-- ============================================================
-- Migration 064 failed to insert skill_damage_formulas (4-7)
-- because slugs 'coeff' and 'flat_add' already exist
-- (unique constraint on skill_damage_formulas.slug).
--
-- Fix: use distinct slugs for the new formula types and
-- complete the missing skill_effects_mapping rows.
-- ============================================================

-- 1. Insert missing skill_damage_formulas with unique slugs
INSERT INTO public.skill_damage_formulas (id, slug, effect_type_id) VALUES
    (4, 'heal_coeff',        6),   -- heal scaling by stat coefficient
    (5, 'heal_flat',         6),   -- heal flat amount
    (6, 'buff_marker',       5),   -- buff (no formula value; signals skillEffectType)
    (7, 'teleport_marker',   7)    -- teleport_respawn (no formula value)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert skill_effects_mapping (failed previously because formula ids 4-7 were absent)
-- (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id)
INSERT INTO public.skill_effects_mapping (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id) VALUES
    (21, 13, 6, 0,   1, 0, 0, NULL),  -- battle_cry:    buff_marker  value=0
    (22, 14, 4, 1.5, 1, 0, 0, NULL),  -- healing_surge: heal_coeff=1.5 (MagAtk × 1.5)
    (23, 15, 5, 80,  1, 0, 0, NULL),  -- healing_surge: heal_flat=80
    (24, 16, 7, 0,   1, 0, 0, NULL)   -- blink_home:    teleport_marker value=0
ON CONFLICT (id) DO NOTHING;

-- 3. Re-bump formula sequence (was stuck at 3)
SELECT setval('public.skill_effects_id_seq', (SELECT MAX(id) FROM public.skill_damage_formulas));
