-- ============================================================
-- Migration 066: Add 'none' utility entries for skill metadata
-- ============================================================
-- Teleport/utility skills have no meaningful scale_stat or school.
-- Adding 'none' entries avoids forcing them into physical/magical.
-- ============================================================

-- 1. Add 'none' scale stat type
INSERT INTO public.skill_scale_type (id, name, slug) OVERRIDING SYSTEM VALUE VALUES (3, 'None', 'none')
ON CONFLICT DO NOTHING;

-- 2. Add 'none' school
INSERT INTO public.skill_school (id, name, slug) OVERRIDING SYSTEM VALUE VALUES (9, 'None', 'none')
ON CONFLICT DO NOTHING;

-- 3. Update Blink Home (skill id=15) to use none/none
UPDATE public.skills
SET scale_stat_id = 3,
    school_id     = 9
WHERE slug = 'blink_home';
