-- ============================================================================
-- DEV-ONLY test content: repeatable errand (cooldown enforcement pin).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_repeatable.sql
-- Then reload world content (NO restart): admin op reloadWorldContent via
-- gm_bot (chunk merges dialogues/quests by id/slug).
--
-- What: quest dev_repeatable_errand (id 9001, repeatable, cooldown 60 s)
-- from a new dev NPC (id 9001) near the village: one reach step (walk a
-- few units, auto) -> turnin. Reward 1 gold (repeat-safe pittance).
-- Expected live sequence: accept -> reach -> turnin -> immediate re-accept
-- REFUSED (cooldown) -> accept OK after 60 s.
-- Idempotent: re-runnable (deletes its own rows by id first).
-- Test id range 9000+ (documented, setval'd past to avoid seq collisions).
-- ============================================================================

BEGIN;

-- Clean previous application (order: children first).
DELETE FROM public.dialogue_edge WHERE from_node_id IN
  (SELECT id FROM public.dialogue_node WHERE dialogue_id = 9001);
DELETE FROM public.dialogue_node WHERE dialogue_id = 9001;
DELETE FROM public.npc_dialogue WHERE npc_id = 9001 AND dialogue_id = 9001;
DELETE FROM public.dialogue WHERE id = 9001;
DELETE FROM public.quest_reward WHERE quest_id = 9001;
DELETE FROM public.quest_step WHERE quest_id = 9001;
DELETE FROM public.player_quest WHERE quest_id = 9001;
DELETE FROM public.quest WHERE id = 9001;
DELETE FROM public.npc_placements WHERE npc_id = 9001;
DELETE FROM public.npc WHERE id = 9001;

-- Dev NPC near the village (Varan stands at 585,-3300).
INSERT INTO public.npc (id, name, race_id, level, current_health, current_mana,
                        is_dead, slug, radius, is_interactable, npc_type)
OVERRIDING SYSTEM VALUE
VALUES (9001, 'DevErrandBoard', 1, 1, 100, 10,
        false, 'dev_errand_board', 100, true, 1);

INSERT INTO public.npc_placements (id, npc_id, zone_id, x, y, z, rot_z)
VALUES (9001, 9001, 1, 800, -3200, 200, 0);

-- Quest: one reach step (auto), repeatable with a 60 s cooldown.
INSERT INTO public.quest (id, slug, min_level, repeatable, cooldown_sec,
                          giver_npc_id, turnin_npc_id, client_quest_key)
VALUES (9001, 'dev_repeatable_errand', 1, true, 60,
        9001, 9001, 'quest.dev_repeatable_errand');

INSERT INTO public.quest_step (id, quest_id, step_index, step_type, params, completion_mode)
VALUES (9002, 9001, 0, 'reach', '{"x": 850.0, "y": -3200.0, "radius": 300.0}', 'auto');

INSERT INTO public.quest_reward (id, quest_id, reward_type, item_id, quantity, amount, is_hidden)
VALUES (9002, 9001, 'gold', NULL, 1, 1, false);

-- Minimal dialogue: greeting -> hub; hub: accept (offer) / turnin / farewell.
-- Accept edge admits re-offers (turned_in): the manager enforces cooldown.
INSERT INTO public.dialogue (id, slug, version, start_node_id)
VALUES (9001, 'dev_repeatable_main', 1, 9005);

INSERT INTO public.dialogue_node (id, dialogue_id, type, speaker_npc_id, client_node_key)
VALUES (9005, 9001, 'line', 9001, 'dev_repeat.greeting'),
       (9006, 9001, 'choice_hub', 9001, 'dev_repeat.hub'),
       (9007, 9001, 'line', 9001, 'dev_repeat.accepted'),
       (9008, 9001, 'line', 9001, 'dev_repeat.thanks'),
       (9009, 9001, 'end', 9001, NULL);

INSERT INTO public.dialogue_edge (id, from_node_id, to_node_id, order_index,
                                  client_choice_key, condition_group, action_group)
VALUES
 (9006, 9005, 9006, 0, 'dev_repeat.continue', NULL, NULL),
 (9007, 9006, 9007, 0, 'dev_repeat.accept',
   '[{"any": [{"slug": "dev_repeatable_errand", "type": "quest", "state": "not_started"}, {"slug": "dev_repeatable_errand", "type": "quest", "state": "turned_in"}]}]',
   '[{"slug": "dev_repeatable_errand", "type": "offer_quest"}]'),
 (9008, 9007, 9006, 0, 'dev_repeat.back', NULL, NULL),
 (9009, 9006, 9008, 0, 'dev_repeat.turnin',
   '[{"slug": "dev_repeatable_errand", "type": "quest", "state": "completed"}]',
   '[{"slug": "dev_repeatable_errand", "type": "turn_in_quest"}]'),
 (9010, 9008, 9009, 0, 'dev_repeat.farewell', NULL, NULL),
 (9011, 9006, 9009, 99, 'dev_repeat.farewell', NULL, NULL);

INSERT INTO public.npc_dialogue (npc_id, dialogue_id, priority, condition_group)
VALUES (9001, 9001, 0, NULL);

-- Keep sequences past the test range.
SELECT setval('quest_id_seq', GREATEST((SELECT last_value FROM quest_id_seq), 9100));
SELECT setval('quest_step_id_seq', GREATEST((SELECT last_value FROM quest_step_id_seq), 9100));
SELECT setval('dialogue_id_seq', GREATEST((SELECT last_value FROM dialogue_id_seq), 9100));
SELECT setval('dialogue_node_id_seq', GREATEST((SELECT last_value FROM dialogue_node_id_seq), 9100));
SELECT setval('dialogue_edge_id_seq', GREATEST((SELECT last_value FROM dialogue_edge_id_seq), 9100));
SELECT setval('npc_placements_id_seq', GREATEST((SELECT last_value FROM npc_placements_id_seq), 9100));
DO $$ DECLARE s text := pg_get_serial_sequence('npc', 'id');
BEGIN EXECUTE format('SELECT setval(%L, GREATEST((SELECT last_value FROM %s), 9100))', s, s); END $$;

COMMIT;

-- Verification (expect 1 quest / 1 step / 1 reward / 5 nodes / 6 edges).
SELECT id, slug, repeatable, cooldown_sec FROM quest WHERE id = 9001;
SELECT step_index, step_type FROM quest_step WHERE quest_id = 9001 ORDER BY step_index;
