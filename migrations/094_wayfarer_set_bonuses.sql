-- 094_wayfarer_set_bonuses.sql
-- First item set: "Wayfarer garb" (starter leather + old sword).
-- Set-bonus plumbing (set_bonus CTE in get_character_attributes) already
-- ships; these rows make it live: 2 pieces -> +3 physical_attack,
-- 3 pieces -> +2 crit_chance.
INSERT INTO public.item_sets (name, slug)
VALUES ('Wayfarer garb', 'wayfarer_garb')
ON CONFLICT DO NOTHING;

INSERT INTO public.item_set_members (set_id, item_id)
SELECT s.id, i.id FROM public.item_sets s, public.items i
WHERE s.slug = 'wayfarer_garb' AND i.slug IN ('worn_old_sword', 'leather_chestguard', 'leather_boots')
ON CONFLICT DO NOTHING;

INSERT INTO public.item_set_bonuses (set_id, pieces_required, attribute_id, bonus_value)
SELECT s.id, 2, ea.id, 3 FROM public.item_sets s, public.entity_attributes ea
WHERE s.slug = 'wayfarer_garb' AND ea.slug = 'physical_attack'
  AND NOT EXISTS (SELECT 1 FROM public.item_set_bonuses b
                  WHERE b.set_id = s.id AND b.pieces_required = 2 AND b.attribute_id = ea.id);

INSERT INTO public.item_set_bonuses (set_id, pieces_required, attribute_id, bonus_value)
SELECT s.id, 3, ea.id, 2 FROM public.item_sets s, public.entity_attributes ea
WHERE s.slug = 'wayfarer_garb' AND ea.slug = 'crit_chance'
  AND NOT EXISTS (SELECT 1 FROM public.item_set_bonuses b
                  WHERE b.set_id = s.id AND b.pieces_required = 3 AND b.attribute_id = ea.id);
