-- ============================================================================
-- DEV-ONLY test content: short quest chain (kill 2 arena foxes -> 1 hide).
-- NEVER part of migrations or the prod dump. Apply to the DEV database only:
--   docker exec -i mmorpg_prototype_db psql -U postgres -d mmo_prototype \
--     < scripts/dev_quest_short.sql
-- Then bounce game-server + chunk-server (dialogues/quests push at boot).
--
-- What: quest dev_short_chain (id 9000) from a new dev NPC near the village
-- (id 9000, no Varan dialogue surgery): step0 kill 2x ForestFox (mob 4,
-- arena foxes count — same template) -> step1 collect 1x animal_hide
-- (item 57) -> turnin. Rewards: 1x small_health_potion (item 46) + 5g.
-- No manual/report step: accept -> hunt -> harvest -> turnin.
-- Idempotent: re-runnable (deletes its own rows by id first).
-- Test id range 9000+ (documented, setval'd past to avoid seq collisions).
-- ============================================================================

BEGIN;

-- Clean previous application (order: children first).
DELETE FROM public.dialogue_edge WHERE from_node_id IN
  (SELECT id FROM public.dialogue_node WHERE dialogue_id = 9000);
DELETE FROM public.dialogue_node WHERE dialogue_id = 9000;
DELETE FROM public.npc_dialogue WHERE npc_id = 9000 AND dialogue_id = 9000;
DELETE FROM public.dialogue WHERE id = 9000;
DELETE FROM public.quest_reward WHERE quest_id = 9000;
DELETE FROM public.quest_step WHERE quest_id = 9000;
DELETE FROM public.quest WHERE id = 9000;
DELETE FROM public.npc_placements WHERE npc_id = 9000;
DELETE FROM public.npc WHERE id = 9000;

-- Dev NPC near the village (Varan stands at 585,-3300).
INSERT INTO public.npc (id, name, race_id, level, current_health, current_mana,
                        is_dead, slug, radius, is_interactable, npc_type)
OVERRIDING SYSTEM VALUE
VALUES (9000, 'DevFoxHelper', 1, 1, 100, 10,
        false, 'dev_fox_helper', 100, true, 1);

INSERT INTO public.npc_placements (id, npc_id, zone_id, x, y, z, rot_z)
VALUES (9000, 9000, 1, 700, -3200, 200, 0);

-- Quest: kill 2 foxes (auto) -> collect 1 hide (auto). Non-repeatable like prod.
INSERT INTO public.quest (id, slug, min_level, repeatable, cooldown_sec,
                          giver_npc_id, turnin_npc_id, client_quest_key)
VALUES (9000, 'dev_short_chain', 1, false, 0,
        9000, 9000, 'quest.dev_short_chain');

INSERT INTO public.quest_step (id, quest_id, step_index, step_type, params, completion_mode)
VALUES (9000, 9000, 0, 'kill', '{"count": 2, "mob_id": 4}', 'auto'),
       (9001, 9000, 1, 'collect', '{"count": 1, "item_id": 57}', 'auto');

INSERT INTO public.quest_reward (id, quest_id, reward_type, item_id, quantity, amount, is_hidden)
VALUES (9000, 9000, 'item', 46, 1, 0, false),
       (9001, 9000, 'gold', NULL, 1, 5, false);

-- Minimal dialogue: greeting -> hub; hub: accept (offer) / turnin / farewell.
INSERT INTO public.dialogue (id, slug, version, start_node_id)
VALUES (9000, 'dev_short_main', 1, 9000);

INSERT INTO public.dialogue_node (id, dialogue_id, type, speaker_npc_id, client_node_key)
VALUES (9000, 9000, 'line', 9000, 'dev_short.greeting'),
       (9001, 9000, 'choice_hub', 9000, 'dev_short.hub'),
       (9002, 9000, 'line', 9000, 'dev_short.accepted'),
       (9003, 9000, 'line', 9000, 'dev_short.thanks'),
       (9004, 9000, 'end', 9000, NULL);

INSERT INTO public.dialogue_edge (id, from_node_id, to_node_id, order_index,
                                  client_choice_key, condition_group, action_group)
VALUES
 (9000, 9000, 9001, 0, 'dev_short.continue', NULL, NULL),
 (9001, 9001, 9002, 0, 'dev_short.accept',
   '[{"any": [{"slug": "dev_short_chain", "type": "quest", "state": "not_started"}]}]',
   '[{"slug": "dev_short_chain", "type": "offer_quest"}]'),
 (9002, 9002, 9001, 0, 'dev_short.back', NULL, NULL),
 (9003, 9001, 9003, 0, 'dev_short.turnin',
   '[{"slug": "dev_short_chain", "type": "quest", "state": "completed"}]',
   '[{"slug": "dev_short_chain", "type": "turn_in_quest"}]'),
 (9004, 9003, 9004, 0, 'dev_short.farewell', NULL, NULL),
 (9005, 9001, 9004, 99, 'dev_short.farewell', NULL, NULL);

INSERT INTO public.npc_dialogue (npc_id, dialogue_id, priority, condition_group)
VALUES (9000, 9000, 0, NULL);

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

-- Verification (expect 1/2/2/6/1 rows).
SELECT id, slug FROM quest WHERE id = 9000;
SELECT step_index, step_type, params FROM quest_step WHERE quest_id = 9000 ORDER BY step_index;
SELECT reward_type, item_id, quantity, amount FROM quest_reward WHERE quest_id = 9000;
SELECT id, client_choice_key FROM dialogue_edge WHERE id BETWEEN 9000 AND 9005 ORDER BY id;
SELECT * FROM npc WHERE id = 9000;
