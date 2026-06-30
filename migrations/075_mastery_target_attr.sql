-- 075_mastery_target_attr.sql
-- Add target_attribute_slug to mastery_definitions so milestone buffs apply to the
-- correct attribute (magical_attack for staff, physical_attack for everything else).

ALTER TABLE public.mastery_definitions
ADD COLUMN target_attribute_slug VARCHAR(60) DEFAULT 'physical_attack' NOT NULL;

UPDATE public.mastery_definitions
SET target_attribute_slug = 'magical_attack'
WHERE slug = 'staff_mastery';
