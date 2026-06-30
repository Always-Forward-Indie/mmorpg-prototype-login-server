-- 077_swift_feet_passive.sql
-- Add a passive skill "Swift Feet" that grants +3 flat move_speed.
-- Available to both classes at level 5 for 1 SP / 100 gold.

INSERT INTO public.skills (id, name, slug, scale_stat_id, school_id, animation_name, is_passive)
OVERRIDING SYSTEM VALUE
VALUES (16, 'Swift Feet', 'swift_feet', 1, 1, NULL, TRUE);

INSERT INTO public.skill_effect_instances (id, skill_id, order_idx, target_type_id)
VALUES (17, 16, 1, 1);

INSERT INTO public.skill_effects_mapping (id, effect_instance_id, effect_id, value, level, tick_ms, duration_ms, attribute_id)
VALUES (25, 17, 3, 0, 1, 0, 0, NULL);

INSERT INTO public.passive_skill_modifiers (id, skill_id, attribute_slug, modifier_type, value)
VALUES (5, 16, 'move_speed', 'flat', 3);

INSERT INTO public.class_skill_tree (id, class_id, skill_id, required_level, is_default, prerequisite_skill_id, skill_point_cost, gold_cost, max_level, requires_book, skill_book_item_id)
VALUES (27, 1, 16, 5, FALSE, NULL, 1, 100, 1, FALSE, NULL),
       (28, 2, 16, 5, FALSE, NULL, 1, 100, 1, FALSE, NULL);
