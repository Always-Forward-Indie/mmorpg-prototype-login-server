-- ============================================================
-- Migration 065: Register skill buffs in status_effects
-- ============================================================
-- skill_active_effects defines WHAT effect a skill applies.
-- player_active_effect stores INSTANCES of named status_effects.
-- The insert_player_active_effect query does:
--   (SELECT id FROM status_effects WHERE slug = $effectSlug)
-- with status_effect_id NOT NULL — so every effect slug that
-- applySkillEffects may produce MUST have a row in status_effects.
--
-- This migration adds the Battle Cry buff template so it can be
-- persisted via saveActiveEffect when needed.
-- ============================================================

-- 1. Add Battle Cry buff template
INSERT INTO public.status_effects (slug, category, duration_sec) VALUES
    ('battle_cry_phys_atk', 'buff', 30)
ON CONFLICT (slug) DO NOTHING;

-- 2. Link it to the physical_attack attribute with a flat +25 modifier
--    (modifier_type 'flat_add' matches the existing enum pattern;
--     look up entity_attributes.id for 'physical_attack')
INSERT INTO public.status_effect_modifiers (status_effect_id, attribute_id, modifier_type, value)
SELECT
    se.id,
    ea.id,
    'flat'::effect_modifier_type,
    25
FROM public.status_effects se
CROSS JOIN public.entity_attributes ea
WHERE se.slug = 'battle_cry_phys_atk'
  AND ea.slug = 'physical_attack'
ON CONFLICT DO NOTHING;
