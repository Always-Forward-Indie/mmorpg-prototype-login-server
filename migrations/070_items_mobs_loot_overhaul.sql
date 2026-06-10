-- Migration 070 Part 1: Cleanup old data + Update existing items + Insert new items
-- Complete item/mob/loot/quest/vendor/dialogue overhaul

BEGIN;

-- ============================================================================
-- SECTION 1: CLEANUP
-- ============================================================================

DELETE FROM public.character_equipment;
DELETE FROM public.player_inventory;
DELETE FROM public.class_starter_items;
DELETE FROM public.vendor_inventory;
DELETE FROM public.mob_loot_info;
DELETE FROM public.item_attributes_mapping;
DELETE FROM public.item_use_effects;
DELETE FROM public.item_class_restrictions;

DELETE FROM public.quest_reward WHERE quest_id = 2;
DELETE FROM public.quest_step WHERE quest_id = 2;
DELETE FROM public.quest WHERE id = 2;

DELETE FROM public.dialogue_edge WHERE from_node_id IN (600,601,602,603,604,605,606,607,608,609,610,611,699,650,651,652,660,661,662,663,669) OR to_node_id IN (600,601,602,603,604,605,606,607,608,609,610,611,699,650,651,652,660,661,662,663,669);
DELETE FROM public.dialogue_node WHERE dialogue_id IN (6, 7, 8);
DELETE FROM public.npc_dialogue WHERE npc_id = 6;
DELETE FROM public.dialogue WHERE id IN (6, 7, 8);

DELETE FROM public.spawn_zone_mobs;
DELETE FROM public.spawn_zones;

DELETE FROM public.mob_stat WHERE mob_id IN (1, 2);
DELETE FROM public.mob_skills WHERE mob_id IN (1, 2);
DELETE FROM public.mob WHERE id IN (1, 2);

DELETE FROM public.items WHERE id NOT IN (2, 16, 18, 19, 20, 21, 22, 23, 24, 25, 26);

-- ============================================================================
-- SECTION 2: UPDATE EXISTING ITEMS
-- ============================================================================

-- Shield: Wooden Shield -> Старый дубовый щит
UPDATE public.items SET
  name = 'Старый дубовый щит',
  slug = 'old_oak_shield',
  description = 'Старый дубовый щит, повидавший немало битв, но всё ещё крепкий.',
  rarity_id = 2,
  durability_max = 120,
  vendor_price_buy = 120,
  vendor_price_sell = 36,
  level_requirement = 3,
  is_harvest = false
WHERE id = 2;

-- Skill book sell prices (~30% of buy)
UPDATE public.items SET vendor_price_sell = 150 WHERE id = 18;
UPDATE public.items SET vendor_price_sell = 80  WHERE id = 19;
UPDATE public.items SET vendor_price_sell = 120 WHERE id = 20;
UPDATE public.items SET vendor_price_sell = 240 WHERE id = 21;
UPDATE public.items SET vendor_price_sell = 150 WHERE id = 22;
UPDATE public.items SET vendor_price_sell = 270 WHERE id = 23;
UPDATE public.items SET vendor_price_sell = 350 WHERE id = 24;
UPDATE public.items SET vendor_price_sell = 180 WHERE id = 25;
UPDATE public.items SET vendor_price_sell = 360 WHERE id = 26;
-- Migration 070 Part 2: New Items (29-75)

-- Weapons (type=1)
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (29, 'Изношенный старый меч', 'worn_old_sword', 'Самое базовое оружие воина. Лезвие покрыто зазубринами, но в умелых руках ещё послужит.', false, 1, 4.0, 1, 1, false, true, true, 80, 35, 10, 6, 1, true, false, false, false, 'sword_mastery') ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (30, 'Треснувший деревянный посох', 'cracked_wooden_staff', 'Самое базовое оружие мага. По дереву пошли трещины, но магическая энергия ещё течёт сквозь него.', false, 1, 2.5, 1, 1, false, true, true, 60, 35, 10, 6, 1, true, false, false, false, 'staff_mastery') ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (31, 'Острый меч', 'sharp_sword', 'Хорошо заточенный клинок из добротной стали. Надёжное оружие для опытного воина.', false, 1, 4.5, 2, 1, false, true, true, 100, 140, 42, 6, 3, true, false, false, false, 'sword_mastery') ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (32, 'Прочный посох', 'sturdy_staff', 'Крепкий посох из выдержанного дуба с лёгким магическим отблеском.', false, 1, 2.5, 2, 1, false, true, true, 90, 140, 42, 6, 3, true, false, false, false, 'staff_mastery') ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (33, 'Рунный посох', 'rune_staff', 'Посох покрытый светящимися рунами. Значительно усиливает магические способности владельца.', false, 1, 3.0, 3, 1, false, true, true, 110, 500, 150, 6, 6, true, false, false, false, 'staff_mastery') ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (34, 'Меч падшего воина', 'fallen_warrior_sword', 'Клинок воина павшего в великой битве. Сталь всё ещё хранит память о былом владельце и его силе.', false, 1, 5.0, 3, 1, false, true, true, 120, 500, 150, 6, 6, true, false, false, false, 'sword_mastery') ON CONFLICT DO NOTHING;

-- Armor (type=2)
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (35, 'Поношенные дырявые сапоги', 'worn_torn_boots', 'Самые базовые сапоги. Дыры в подошве, но это лучше чем идти босиком.', false, 2, 1.5, 1, 1, false, true, true, 50, 20, 6, 4, 1, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (36, 'Потрёпанный нагрудник', 'tattered_breastplate', 'Самая базовая броня для воина. Кожа местами протёрта, но грудную клетку защитит.', false, 2, 3.0, 1, 1, false, true, true, 70, 30, 9, 2, 1, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (37, 'Драная мантия', 'torn_robe', 'Самая базовая броня для мага. Мантия побывала в переделках, но магическую ауру сохраняет.', false, 2, 1.5, 1, 1, false, true, true, 50, 30, 9, 2, 1, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (38, 'Кожаный нагрудник', 'leather_chestguard', 'Добротный нагрудник из толстой выделанной кожи. Хорошая защита без лишнего веса.', false, 2, 3.5, 2, 1, false, true, true, 100, 130, 39, 2, 3, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (39, 'Мантия ученика', 'apprentice_robe', 'Мантия подмастерья магической гильдии. Ткань пропитана защитными чарами.', false, 2, 1.8, 2, 1, false, true, true, 80, 130, 39, 2, 3, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (40, 'Кожаные сапоги', 'leather_boots', 'Крепкие кожаные сапоги. Ноги скажут спасибо после долгого перехода.', false, 2, 2.0, 2, 1, false, true, true, 70, 90, 27, 4, 3, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (41, 'Стёганый доспех', 'quilted_armor', 'Многослойный стёганый доспех усиленный металлическими вставками. Серьёзная защита для бывалых воинов.', false, 2, 5.0, 3, 1, false, true, true, 140, 420, 126, 2, 6, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (42, 'Плащ Мудреца', 'sage_cloak', 'Длинный плащ пропитанный мощной защитной магией. Такие носят только уважаемые чародеи.', false, 2, 2.0, 3, 1, false, true, true, 100, 420, 126, 2, 6, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (43, 'Прочные сапоги', 'sturdy_boots', 'Сапоги усиленные стальными накладками. В таких можно и по болоту пройти и в бою устоять.', false, 2, 2.5, 3, 1, false, true, true, 90, 300, 90, 4, 6, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (44, 'Амулет Звериного Чутья', 'beast_sense_amulet', 'Древний амулет обостриющий инстинкты носящего. Позволяет чувствовать опасность до того как она наступит.', false, 7, 0.3, 3, 1, false, true, true, 100, 380, 114, 10, 6, true, false, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (45, 'Светящееся Кольцо', 'glowing_ring', 'Кольцо излучающее мягкий голубоватый свет. Наполняет владельца дополнительной магической энергией.', false, 7, 0.1, 3, 1, false, true, true, 100, 350, 105, 9, 6, true, false, false, false, NULL) ON CONFLICT DO NOTHING;

-- Potions (type=3)
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (46, 'Малое зелье лечения', 'small_health_potion', 'Красное зелье которое восстанавливает немного здоровья.', false, 3, 0.5, 1, 64, false, false, true, 100, 10, 3, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (47, 'Малое зелье маны', 'small_mana_potion', 'Синее зелье которое восстанавливает немного маны.', false, 3, 0.5, 1, 64, false, false, true, 100, 10, 3, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (48, 'Малое зелье скорости', 'small_speed_potion', 'Зелье которое накладывает эффект увеличения скорости передвижения на некоторое время.', false, 3, 0.5, 1, 64, false, false, true, 100, 15, 4, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (49, 'Малое зелье защиты', 'small_defense_potion', 'Зелье которое накладывает эффект увеличения физической защиты на некоторое время.', false, 3, 0.5, 1, 64, false, false, true, 100, 15, 4, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (50, 'Малое зелье силы', 'small_strength_potion', 'Зелье которое накладывает эффект увеличения физической силы на некоторое время.', false, 3, 0.5, 1, 64, false, false, true, 100, 15, 4, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (51, 'Малое зелье магии', 'small_magic_potion', 'Зелье которое накладывает эффект увеличения интеллекта на некоторое время.', false, 3, 0.5, 1, 64, false, false, true, 100, 15, 4, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;

-- Food (type=4)
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (52, 'Холодная похлёбка', 'cold_stew', 'Остывшая похлёбка сделанная из того что было под рукой.', false, 4, 0.3, 1, 64, false, false, true, 100, 6, 2, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (53, 'Свежий хлеб', 'fresh_bread', 'Свежий хрустящий хлеб. Восстанавливает силы.', false, 4, 0.2, 1, 64, false, false, true, 100, 8, 2, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (54, 'Яблоко', 'apple', 'Красное спелое яблоко.', false, 4, 0.1, 1, 64, false, false, true, 100, 5, 1, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (55, 'Жареное мясо', 'roasted_meat', 'Хорошо прожаренное мясо животного. Придаёт сил.', false, 4, 0.4, 2, 64, false, false, true, 100, 25, 7, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (56, 'Сладкое вино', 'sweet_wine', 'Вкусное и сладкое вино. Пробуждает магические способности.', false, 4, 0.3, 2, 64, false, false, true, 100, 25, 7, NULL, 0, false, false, true, false, NULL) ON CONFLICT DO NOTHING;

-- Resources (type=6)
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (57, 'Шкура животного', 'animal_hide', 'Шкура которую можно собрать с животных. Используется в ремесле и торговле.', false, 6, 0.4, 1, 64, false, false, true, 100, 7, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (58, 'Кости животного', 'animal_bones', 'Кости которые можно собрать с животных.', false, 6, 0.5, 1, 64, false, false, true, 100, 5, 1, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (59, 'Когти животного', 'animal_claws', 'Когти которые можно собрать с животных. Острые и прочные.', false, 6, 0.2, 1, 64, false, false, true, 100, 7, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (60, 'Жир животного', 'animal_fat', 'Жир который можно собрать с животных. Горит долго и ярко.', false, 6, 0.3, 1, 64, false, false, true, 100, 5, 1, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (61, 'Кровь животного', 'animal_blood', 'Кровь которую можно собрать с животных. Ценится алхимиками.', false, 6, 0.5, 1, 64, false, false, true, 100, 5, 1, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (62, 'Каменная крошка', 'stone_fragment', 'Частицы камней которые можно собрать с големов. Содержат следы магии.', false, 6, 0.4, 2, 64, false, false, true, 100, 15, 4, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (63, 'Прах нежити', 'undead_dust', 'Прах который можно собрать с нежити. Тускло светится в темноте.', false, 6, 0.2, 2, 64, false, false, true, 100, 18, 5, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (64, 'Обломок клинка', 'blade_fragment', 'Обломок старого клинка который выпадает с разных мобов.', false, 6, 1.0, 3, 64, false, false, true, 100, 35, 10, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (65, 'Осколок ядра', 'core_shard', 'Осколок магического ядра который можно собрать с магически созданных существ.', false, 6, 0.3, 3, 64, false, false, true, 100, 45, 13, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (66, 'Ржавая пластина', 'rusty_plate', 'Ржавая пластина с какой-то части доспехов. Выпадает обычно с нежити.', false, 6, 1.2, 2, 64, false, false, true, 100, 12, 3, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (67, 'Окровавленный клок ткани', 'bloody_cloth_scrap', 'Клок одежды какой-то жертвы. Продаётся за бесценок.', false, 6, 0.1, 1, 64, false, false, true, 100, 5, 1, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (68, 'Ржавый наконечник стрелы', 'rusty_arrowhead', 'Старый ржавый наконечник стрелы который застрял в теле и выпадает с мобов.', false, 6, 0.1, 1, 64, false, false, true, 100, 6, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (69, 'Сломанный нож', 'broken_knife', 'Старый сломанный нож который застрял в теле и выпадает с мобов.', false, 6, 0.3, 1, 64, false, false, true, 100, 7, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (70, 'Старый ошейник', 'old_collar', 'Старый ошейник который выпадает с мобов типа животных.', false, 6, 0.2, 1, 64, false, false, true, 100, 8, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (71, 'Потрёпанный дневник', 'tattered_diary', 'Потрёпанный дневник неизвестного путника. Страницы едва читаемы.', false, 6, 0.3, 2, 64, false, false, true, 100, 22, 6, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (72, 'Птичье перо', 'bird_feather', 'Обычное птичье перо. Лёгкое как ветер.', false, 6, 0.05, 1, 64, false, false, true, 100, 4, 1, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (73, 'Сломанная печать', 'broken_seal', 'Старая сломанная магическая печать. Выпадает с мобов созданных с помощью магии.', false, 6, 0.2, 2, 64, false, false, true, 100, 20, 6, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (74, 'Магический камень', 'magical_stone', 'Светящийся камень пропитанный магической энергией. Выпадает с магических мобов.', false, 6, 0.3, 3, 64, false, false, true, 100, 55, 16, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.items OVERRIDING SYSTEM VALUE VALUES (75, 'Мясо животного', 'animal_meat', 'Свежее мясо добытое с животного. Можно приготовить или продать.', false, 6, 1.0, 1, 64, false, false, true, 100, 8, 2, NULL, 0, false, true, false, false, NULL) ON CONFLICT DO NOTHING;
-- Migration 070 Part 3: Item Attributes, Use Effects, Class Restrictions

-- ============================================================================
-- ITEM ATTRIBUTES (equip bonuses)
-- attribute_id: 3=str 4=int 6=phys_def 12=phys_atk 13=mag_atk 15=evasion 2=max_mana
-- ============================================================================

-- Weapons
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (15, 29, 3, 2, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (16, 29, 12, 3, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (17, 30, 4, 2, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (18, 30, 13, 3, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (19, 31, 3, 5, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (20, 31, 12, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (21, 32, 4, 5, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (22, 32, 13, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (23, 33, 4, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (24, 33, 13, 14, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (25, 34, 3, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (26, 34, 12, 14, 'equip') ON CONFLICT DO NOTHING;

-- Armor
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (27, 35, 6, 2, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (28, 36, 6, 3, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (29, 37, 6, 3, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (30, 38, 6, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (31, 39, 6, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (32, 40, 6, 5, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (33, 41, 6, 15, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (34, 42, 6, 15, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (35, 43, 6, 10, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (36, 44, 15, 8, 'equip') ON CONFLICT DO NOTHING;
INSERT INTO public.item_attributes_mapping OVERRIDING SYSTEM VALUE VALUES (37, 45, 2, 30, 'equip') ON CONFLICT DO NOTHING;

-- Update shield attributes
UPDATE public.item_attributes_mapping SET value = 5 WHERE item_id = 2 AND attribute_id = 6;
UPDATE public.item_attributes_mapping SET value = 3 WHERE item_id = 2 AND attribute_id = 17;

-- ============================================================================
-- ITEM USE EFFECTS
-- ============================================================================

-- Instant potions
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (5, 46, 'hp_restore_10', 'hp', 10, true, 0, 0, 30) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (6, 47, 'mp_restore_10', 'mp', 10, true, 0, 0, 30) ON CONFLICT DO NOTHING;

-- Buff potions (180s, tick 1s, cd 60s)
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (7, 48, 'speed_boost_5', 'move_speed', 5, false, 180, 1000, 60) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (8, 49, 'defense_boost_3', 'physical_defense', 3, false, 180, 1000, 60) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (9, 50, 'strength_boost_3', 'strength', 3, false, 180, 1000, 60) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (10, 51, 'intelligence_boost_3', 'intelligence', 3, false, 180, 1000, 60) ON CONFLICT DO NOTHING;

-- Food
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (11, 52, 'stew_hp_buff', 'max_health', 10, false, 60, 1000, 120) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (12, 53, 'bread_hp_restore', 'hp', 15, true, 0, 0, 60) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (13, 54, 'apple_hp_buff', 'max_health', 15, false, 60, 1000, 120) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (14, 55, 'meat_phys_atk_buff', 'physical_attack', 5, false, 180, 1000, 120) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (15, 56, 'wine_mag_atk_buff', 'magical_attack', 5, false, 180, 1000, 120) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (16, 53, 'bread_mp_restore', 'mp', 10, true, 0, 0, 60) ON CONFLICT DO NOTHING;
INSERT INTO public.item_use_effects OVERRIDING SYSTEM VALUE VALUES (17, 52, 'stew_mp_buff', 'max_mana', 5, false, 60, 1000, 120) ON CONFLICT DO NOTHING;

-- ============================================================================
-- ITEM CLASS RESTRICTIONS
-- ============================================================================

-- Warrior-only armor
INSERT INTO public.item_class_restrictions VALUES (36, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (38, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (41, 2) ON CONFLICT DO NOTHING;

-- Mage-only armor
INSERT INTO public.item_class_restrictions VALUES (37, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (39, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (42, 1) ON CONFLICT DO NOTHING;

-- Warrior weapons
INSERT INTO public.item_class_restrictions VALUES (29, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (31, 2) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (34, 2) ON CONFLICT DO NOTHING;

-- Mage weapons
INSERT INTO public.item_class_restrictions VALUES (30, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (32, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.item_class_restrictions VALUES (33, 1) ON CONFLICT DO NOTHING;
-- Migration 070 Part 4: New Mobs + Stats

-- ============================================================================
-- MOB TEMPLATES
-- ============================================================================

INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (3, 'Простой кабан', 2, 2, 120, 10, false, false, 'ForestBoar', 100, 30, 1, 500, 120, 2.0, 1.5, 0.8, true, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (4, 'Простая лиса', 2, 1, 50, 15, false, false, 'ForestFox', 100, 20, 1, 600, 120, 2.5, 1.0, 1.0, true, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (5, 'Скелет', 2, 1, 70, 5, true, false, 'RuinSkeleton', 100, 25, 1, 500, 110, 2.8, 0.7, 0.7, false, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'undead') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (6, 'Простой волк', 2, 3, 150, 20, true, false, 'ForestWolf', 100, 45, 1, 700, 130, 2.0, 1.3, 1.0, false, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (7, 'Матёрый волк', 2, 5, 400, 40, true, false, 'AlphaWolf', 120, 200, 3, 800, 150, 1.8, 1.3, 1.0, false, 30, 0, 'melee', false, true, 8.0, 'on_kill', NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (8, 'Духовный лис', 2, 5, 300, 150, false, false, 'SpiritFox', 120, 180, 3, 600, 140, 2.2, 1.0, 1.2, true, 30, 0, 'melee', false, true, 8.0, 'on_kill', NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (9, 'Лесной медведь', 2, 10, 2000, 50, true, false, 'ForestBear', 200, 800, 6, 900, 180, 2.5, 0.8, 0.7, false, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'beast') ON CONFLICT DO NOTHING;
INSERT INTO public.mob OVERRIDING SYSTEM VALUE VALUES (10, 'Каменный голем', 2, 15, 5000, 200, true, false, 'StoneGolem', 250, 2000, 6, 700, 200, 3.0, 0.5, 0.4, false, 30, 0, 'melee', false, false, 0, NULL, NULL, 0, '', 'elemental') ON CONFLICT DO NOTHING;

-- Mob skills (all get Basic Attack = 1)
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (6, 3, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (7, 4, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (8, 5, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (9, 6, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (10, 7, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (11, 8, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (12, 9, 1, 1) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_skills OVERRIDING SYSTEM VALUE VALUES (13, 10, 1, 1) ON CONFLICT DO NOTHING;

INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (200, 3, 1, 120.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (201, 3, 2, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (202, 3, 3, 7.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (203, 3, 4, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (204, 3, 6, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (205, 3, 7, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (206, 3, 8, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (207, 3, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (208, 3, 10, 0.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (209, 3, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (210, 3, 12, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (211, 3, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (212, 3, 14, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (213, 3, 15, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (214, 3, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (215, 3, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (216, 3, 18, 5.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (217, 3, 19, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (218, 3, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (219, 3, 27, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (220, 3, 28, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (221, 3, 29, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (222, 3, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (223, 3, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (224, 3, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (225, 3, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (226, 3, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (227, 3, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (228, 4, 1, 50.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (229, 4, 2, 15.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (230, 4, 3, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (231, 4, 4, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (232, 4, 6, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (233, 4, 7, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (234, 4, 8, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (235, 4, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (236, 4, 10, 0.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (237, 4, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (238, 4, 12, 7.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (239, 4, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (240, 4, 14, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (241, 4, 15, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (242, 4, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (243, 4, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (244, 4, 18, 7.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (245, 4, 19, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (246, 4, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (247, 4, 27, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (248, 4, 28, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (249, 4, 29, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (250, 4, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (251, 4, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (252, 4, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (253, 4, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (254, 4, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (255, 4, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (256, 5, 1, 70.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (257, 5, 2, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (258, 5, 3, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (259, 5, 4, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (260, 5, 6, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (261, 5, 7, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (262, 5, 8, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (263, 5, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (264, 5, 10, 0.30, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (265, 5, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (266, 5, 12, 9.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (267, 5, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (268, 5, 14, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (269, 5, 15, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (270, 5, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (271, 5, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (272, 5, 18, 3.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (273, 5, 19, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (274, 5, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (275, 5, 27, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (276, 5, 28, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (277, 5, 29, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (278, 5, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (279, 5, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (280, 5, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (281, 5, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (282, 5, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (283, 5, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (284, 6, 1, 150.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (285, 6, 2, 20.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (286, 6, 3, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (287, 6, 4, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (288, 6, 6, 7.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (289, 6, 7, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (290, 6, 8, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (291, 6, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (292, 6, 10, 0.80, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (293, 6, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (294, 6, 12, 15.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (295, 6, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (296, 6, 14, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (297, 6, 15, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (298, 6, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (299, 6, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (300, 6, 18, 6.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (301, 6, 19, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (302, 6, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (303, 6, 27, 7.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (304, 6, 28, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (305, 6, 29, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (306, 6, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (307, 6, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (308, 6, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (309, 6, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (310, 6, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (311, 6, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (312, 7, 1, 400.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (313, 7, 2, 40.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (314, 7, 3, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (315, 7, 4, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (316, 7, 6, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (317, 7, 7, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (318, 7, 8, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (319, 7, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (320, 7, 10, 1.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (321, 7, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (322, 7, 12, 25.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (323, 7, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (324, 7, 14, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (325, 7, 15, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (326, 7, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (327, 7, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (328, 7, 18, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (329, 7, 19, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (330, 7, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (331, 7, 27, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (332, 7, 28, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (333, 7, 29, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (334, 7, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (335, 7, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (336, 7, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (337, 7, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (338, 7, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (339, 7, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (340, 8, 1, 300.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (341, 8, 2, 150.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (342, 8, 3, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (343, 8, 4, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (344, 8, 6, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (345, 8, 7, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (346, 8, 8, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (347, 8, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (348, 8, 10, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (349, 8, 11, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (350, 8, 12, 12.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (351, 8, 13, 20.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (352, 8, 14, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (353, 8, 15, 18.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (354, 8, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (355, 8, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (356, 8, 18, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (357, 8, 19, 6.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (358, 8, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (359, 8, 27, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (360, 8, 28, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (361, 8, 29, 18.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (362, 8, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (363, 8, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (364, 8, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (365, 8, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (366, 8, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (367, 8, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (368, 9, 1, 2000.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (369, 9, 2, 50.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (370, 9, 3, 25.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (371, 9, 4, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (372, 9, 6, 25.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (373, 9, 7, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (374, 9, 8, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (375, 9, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (376, 9, 10, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (377, 9, 11, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (378, 9, 12, 45.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (379, 9, 13, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (380, 9, 14, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (381, 9, 15, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (382, 9, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (383, 9, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (384, 9, 18, 4.50, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (385, 9, 19, 4.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (386, 9, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (387, 9, 27, 20.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (388, 9, 28, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (389, 9, 29, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (390, 9, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (391, 9, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (392, 9, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (393, 9, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (394, 9, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (395, 9, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (396, 10, 1, 5000.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (397, 10, 2, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (398, 10, 3, 30.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (399, 10, 4, 5.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (400, 10, 6, 40.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (401, 10, 7, 30.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (402, 10, 8, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (403, 10, 9, 200.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (404, 10, 10, 2.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (405, 10, 11, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (406, 10, 12, 55.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (407, 10, 13, 10.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (408, 10, 14, 8.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (409, 10, 15, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (410, 10, 16, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (411, 10, 17, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (412, 10, 18, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (413, 10, 19, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (414, 10, 20, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (415, 10, 27, 28.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (416, 10, 28, 3.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (417, 10, 29, 1.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (418, 10, 30, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (419, 10, 31, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (420, 10, 32, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (421, 10, 33, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (422, 10, 34, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.mob_stat OVERRIDING SYSTEM VALUE VALUES (423, 10, 35, 0.00, NULL, NULL) ON CONFLICT DO NOTHING;
-- Migration 070 Part 5: Mob Loot Tables

INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (40, 3, 69, 0.15, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (41, 3, 68, 0.10, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (42, 3, 70, 0.07, false, 1, 1, 'uncommon') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (43, 3, 57, 0.50, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (44, 3, 61, 0.35, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (45, 3, 60, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (46, 3, 58, 0.40, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (47, 3, 75, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (48, 4, 68, 0.07, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (49, 4, 72, 0.18, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (50, 4, 67, 0.10, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (51, 4, 57, 0.45, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (52, 4, 61, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (53, 4, 60, 0.25, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (54, 4, 58, 0.35, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (55, 4, 59, 0.18, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (56, 4, 75, 0.25, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (57, 5, 71, 0.10, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (58, 5, 66, 0.12, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (59, 5, 64, 0.04, false, 1, 1, 'rare') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (60, 5, 16, 0.20, false, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (61, 5, 63, 0.60, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (62, 6, 70, 0.12, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (63, 6, 68, 0.07, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (64, 6, 67, 0.10, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (65, 6, 57, 0.50, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (66, 6, 61, 0.35, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (67, 6, 60, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (68, 6, 58, 0.40, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (69, 6, 59, 0.20, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (70, 6, 75, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (71, 7, 70, 0.28, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (72, 7, 68, 0.15, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (73, 7, 67, 0.18, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (74, 7, 44, 0.07, false, 1, 1, 'very_rare') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (75, 7, 57, 0.60, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (76, 7, 61, 0.45, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (77, 7, 60, 0.40, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (78, 7, 58, 0.50, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (79, 7, 59, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (80, 7, 75, 0.40, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (81, 8, 68, 0.15, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (82, 8, 72, 0.35, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (83, 8, 67, 0.18, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (84, 8, 74, 0.12, false, 1, 1, 'uncommon') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (85, 8, 45, 0.05, false, 1, 1, 'very_rare') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (86, 8, 57, 0.55, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (87, 8, 61, 0.40, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (88, 8, 60, 0.35, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (89, 8, 58, 0.45, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (90, 8, 59, 0.25, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (91, 8, 75, 0.30, true, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (92, 9, 67, 0.45, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (93, 9, 64, 0.18, false, 1, 1, 'uncommon') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (94, 9, 69, 0.28, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (95, 9, 68, 0.18, false, 1, 1, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (96, 9, 57, 0.70, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (97, 9, 61, 0.50, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (98, 9, 60, 0.45, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (99, 9, 58, 0.60, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (100, 9, 59, 0.40, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (101, 9, 75, 0.50, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (102, 10, 16, 1.00, false, 2, 5, 'common') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (103, 10, 73, 0.22, false, 1, 1, 'uncommon') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (104, 10, 74, 0.14, false, 1, 1, 'rare') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (105, 10, 65, 0.40, true, 1, 1, 'uncommon') ON CONFLICT DO NOTHING;
INSERT INTO public.mob_loot_info OVERRIDING SYSTEM VALUE VALUES (106, 10, 62, 0.60, true, 1, 2, 'common') ON CONFLICT DO NOTHING;
-- Migration 070 Part 6: Spawn Zones, Quest, Dialogue, Vendors

-- ============================================================================
-- SPAWN ZONES
-- ============================================================================

-- 1: Fox Glade (replaces Foxes Nest) - ForestFox x25
INSERT INTO public.spawn_zones VALUES (1, 'Fox Glade', 5549.27440860249, 7606.171800291835, 100, 8549.27440860249, 9106.171800291835, 500, 2, 'ANNULUS', -434.657331344104, -973.2708228250776, 5608.287819504758, 8172.50264880794, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (1, 1, 4, 25, '00:01:00') ON CONFLICT DO NOTHING;

-- 2: Wolf Den (replaces Wolf Place) - ForestWolf x8
INSERT INTO public.spawn_zones VALUES (2, 'Wolf Den', -1347.7795661102573, 11060.99297085309, 100, 719.674578427519, 12560.99297085309, 500, 2, 'RECT', -314.05249384136914, 11810.99297085309, 0, 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (2, 2, 6, 8, '00:01:00') ON CONFLICT DO NOTHING;

-- 3: Boar Grove (new) - ForestBoar x10, CIRCLE at (3500, 5000), radius 1800
INSERT INTO public.spawn_zones VALUES (3, 'Boar Grove', 0, 0, 0, 0, 0, 0, 2, 'CIRCLE', 3500.0, 5000.0, 0, 1800, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (3, 3, 3, 10, '00:01:00') ON CONFLICT DO NOTHING;

-- 4: Ruins Outskirts (new) - RuinSkeleton x8, CIRCLE at (18500, -18500), radius 1500
INSERT INTO public.spawn_zones VALUES (4, 'Ruins Outskirts', 0, 0, 0, 0, 0, 0, 2, 'CIRCLE', 18500.0, -18500.0, 0, 1500, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (4, 4, 5, 8, '00:01:00') ON CONFLICT DO NOTHING;

-- 5: Deep Thicket (new) - ForestBear x1 (boss, 5min), CIRCLE at (-5000, 8000), radius 800
INSERT INTO public.spawn_zones VALUES (5, 'Deep Thicket', 0, 0, 0, 0, 0, 0, 2, 'CIRCLE', -5000.0, 8000.0, 0, 800, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (5, 5, 9, 1, '00:05:00') ON CONFLICT DO NOTHING;

-- 6: Stone Circle (new) - StoneGolem x1 (boss, 10min), CIRCLE at (20000, -20000), radius 600
INSERT INTO public.spawn_zones VALUES (6, 'Stone Circle', 0, 0, 0, 0, 0, 0, 2, 'CIRCLE', 20000.0, -20000.0, 0, 600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.spawn_zone_mobs VALUES (6, 6, 10, 1, '00:10:00') ON CONFLICT DO NOTHING;

-- ============================================================================
-- QUEST: varan_fox_menace (rewritten)
-- ============================================================================

INSERT INTO public.quest OVERRIDING SYSTEM VALUE VALUES (2, 'varan_fox_menace', 1, false, 0, 1, 1, 'quest.varan_fox_menace', 'merchants', 50, 0) ON CONFLICT DO NOTHING;

INSERT INTO public.quest_step OVERRIDING SYSTEM VALUE VALUES (8, 2, 0, 'kill', '{"count": 6, "mob_id": 4}', 'quest.varan_fox_menace.kill_foxes', 'auto') ON CONFLICT DO NOTHING;
INSERT INTO public.quest_step OVERRIDING SYSTEM VALUE VALUES (9, 2, 1, 'custom', '{}', 'quest.varan_fox_menace.report_to_varan', 'manual') ON CONFLICT DO NOTHING;
INSERT INTO public.quest_step OVERRIDING SYSTEM VALUE VALUES (10, 2, 2, 'collect', '{"count": 6, "item_id": 57}', 'quest.varan_fox_menace.collect_hides', 'auto') ON CONFLICT DO NOTHING;

INSERT INTO public.quest_reward OVERRIDING SYSTEM VALUE VALUES (4, 2, 'item', 46, 3, 0, false) ON CONFLICT DO NOTHING;
INSERT INTO public.quest_reward OVERRIDING SYSTEM VALUE VALUES (5, 2, 'gold', NULL, 1, 20, false) ON CONFLICT DO NOTHING;
INSERT INTO public.quest_reward OVERRIDING SYSTEM VALUE VALUES (6, 2, 'exp', NULL, 1, 50, false) ON CONFLICT DO NOTHING;

-- ============================================================================
-- VENDOR INVENTORIES
-- ============================================================================

-- Theron (vendor_npc_id=2): All weapons + armor + shield
INSERT INTO public.vendor_inventory VALUES (50, 2, 2, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (51, 2, 29, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (52, 2, 30, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (53, 2, 31, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (54, 2, 32, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (55, 2, 33, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (56, 2, 34, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (57, 2, 35, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (58, 2, 36, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (59, 2, 37, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (60, 2, 38, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (61, 2, 39, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (62, 2, 40, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (63, 2, 41, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (64, 2, 42, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (65, 2, 43, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (66, 2, 44, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (67, 2, 45, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;

-- Milaya (vendor_npc_id=4): Potions + Food
INSERT INTO public.vendor_inventory VALUES (68, 4, 46, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (69, 4, 47, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (70, 4, 48, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (71, 4, 49, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (72, 4, 50, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (73, 4, 51, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (74, 4, 52, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (75, 4, 53, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (76, 4, 54, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (77, 4, 55, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (78, 4, 56, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;

-- Varan (vendor_npc_id=1): Animal resources
INSERT INTO public.vendor_inventory VALUES (79, 1, 57, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (80, 1, 58, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (81, 1, 59, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (82, 1, 60, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (83, 1, 61, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (84, 1, 75, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;

-- Sylara (vendor_npc_id=3): Mage skill books (unchanged)
INSERT INTO public.vendor_inventory VALUES (85, 3, 22, -1, NULL, 0, -1, 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (86, 3, 23, -1, NULL, 0, -1, 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (87, 3, 25, -1, NULL, 0, -1, 0, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (88, 3, 26, -1, NULL, 0, -1, 0, NULL) ON CONFLICT DO NOTHING;

-- Edrik (vendor_npc_id=5): Warrior skill books (unchanged)
INSERT INTO public.vendor_inventory VALUES (89, 5, 18, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (90, 5, 20, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (91, 5, 21, -1, NULL, 0, -1, 3600, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.vendor_inventory VALUES (92, 5, 19, 1, NULL, 1, 1, 86400, NULL) ON CONFLICT DO NOTHING;

-- ============================================================================
-- CLASS STARTER ITEMS (gold only; weapons/armor come from dialogue)
-- ============================================================================

INSERT INTO public.class_starter_items (class_id, item_id, quantity, slot_index)
VALUES (1, 16, 20, 0) ON CONFLICT DO NOTHING;
INSERT INTO public.class_starter_items (class_id, item_id, quantity, slot_index)
VALUES (2, 16, 20, 0) ON CONFLICT DO NOTHING;
-- Migration 070 Part 7: Ruins Dying Stranger Dialogue

-- Dialogue graphs
INSERT INTO public.dialogue OVERRIDING SYSTEM VALUE VALUES (6, 'ruins_dying_stranger_main', 1, 600) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue OVERRIDING SYSTEM VALUE VALUES (7, 'ruins_dying_stranger_replay', 1, 650) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue OVERRIDING SYSTEM VALUE VALUES (8, 'ruins_dying_stranger_items_shortcut', 1, 660) ON CONFLICT DO NOTHING;

-- Dialogue nodes
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (600, 6, 'line', 6, 'npc.ruins_dying_stranger.greeting', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (601, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.first_hub', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (602, 6, 'line', 6, 'npc.ruins_dying_stranger.where_am_i', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (603, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.from_where', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (604, 6, 'line', 6, 'npc.ruins_dying_stranger.what_happened', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (605, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.from_what_happened', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (606, 6, 'line', 6, 'npc.ruins_dying_stranger.tried_to_escape', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (607, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.from_escape', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (608, 6, 'line', 6, 'npc.ruins_dying_stranger.offer_item_text', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (609, 6, 'choice_hub', 6, 'npc.ruins_dying_stranger.accept_hub', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (610, 6, 'line', 6, 'npc.ruins_dying_stranger.farewell_narrative', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (611, 6, 'line', 6, 'npc.ruins_dying_stranger.farewell', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (699, 6, 'end', 6, NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (650, 7, 'line', 6, 'npc.ruins_dying_stranger.replay_farewell', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (651, 7, 'choice_hub', 6, 'npc.ruins_dying_stranger.replay_hub', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (652, 7, 'end', 6, NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (660, 8, 'line', 6, 'npc.ruins_dying_stranger.offer_item_shortcut', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (661, 8, 'choice_hub', 6, 'npc.ruins_dying_stranger.accept_hub', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (662, 8, 'line', 6, 'npc.ruins_dying_stranger.farewell_narrative', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (663, 8, 'line', 6, 'npc.ruins_dying_stranger.farewell', NULL, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_node OVERRIDING SYSTEM VALUE VALUES (669, 8, 'end', 6, NULL, NULL, NULL, NULL) ON CONFLICT DO NOTHING;

-- Dialogue edges (main dialogue 6)
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (145, 600, 601, 0, 'ruins_dying_stranger.choice.continue', NULL, '[{"key": "ruins_dying_stranger.dialogue_started", "type": "set_flag", "bool_value": true}]', false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (146, 601, 602, 0, 'ruins_dying_stranger.choice.where_am_i', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (147, 601, 604, 1, 'ruins_dying_stranger.choice.what_happened', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (148, 601, 608, 2, 'ruins_dying_stranger.choice.useful_items', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (149, 601, 610, 3, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (150, 602, 603, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (151, 603, 604, 0, 'ruins_dying_stranger.choice.what_happened', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (152, 603, 608, 1, 'ruins_dying_stranger.choice.useful_items', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (153, 603, 610, 2, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (154, 604, 605, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (155, 605, 606, 0, 'ruins_dying_stranger.choice.tried_to_escape', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (156, 605, 608, 1, 'ruins_dying_stranger.choice.useful_items', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (157, 605, 610, 2, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (158, 606, 607, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (159, 607, 608, 0, 'ruins_dying_stranger.choice.useful_items', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (160, 607, 610, 1, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (161, 608, 609, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;

-- Edge 162: Warrior accepts gift
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (162, 609, 610, 0, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 2}]', '[{"type": "give_item", "item_id": 29, "quantity": 1}, {"type": "give_item", "item_id": 36, "quantity": 1}, {"type": "give_item", "item_id": 35, "quantity": 1}, {"type": "give_item", "item_id": 46, "quantity": 2}, {"type": "give_item", "item_id": 47, "quantity": 1}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true) ON CONFLICT DO NOTHING;

-- Edge 163: Mage accepts gift
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (163, 609, 610, 1, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 1}]', '[{"type": "give_item", "item_id": 30, "quantity": 1}, {"type": "give_item", "item_id": 37, "quantity": 1}, {"type": "give_item", "item_id": 35, "quantity": 1}, {"type": "give_item", "item_id": 46, "quantity": 2}, {"type": "give_item", "item_id": 47, "quantity": 1}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true) ON CONFLICT DO NOTHING;

INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (164, 609, 610, 2, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (165, 610, 611, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (166, 611, 699, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;

-- Replay path (dialogue 7)
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (167, 650, 651, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (168, 651, 652, 0, 'ruins_dying_stranger.choice.hold_on', NULL, NULL, false) ON CONFLICT DO NOTHING;

-- Shortcut path (dialogue 8)
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (169, 660, 661, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;

-- Edge 170: Shortcut Warrior accept
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (170, 661, 662, 0, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 2}]', '[{"type": "give_item", "item_id": 29, "quantity": 1}, {"type": "give_item", "item_id": 36, "quantity": 1}, {"type": "give_item", "item_id": 35, "quantity": 1}, {"type": "give_item", "item_id": 46, "quantity": 2}, {"type": "give_item", "item_id": 47, "quantity": 1}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true) ON CONFLICT DO NOTHING;

-- Edge 171: Shortcut Mage accept
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (171, 661, 662, 1, 'ruins_dying_stranger.choice.accept', '[{"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}, {"type": "class", "class_id": 1}]', '[{"type": "give_item", "item_id": 30, "quantity": 1}, {"type": "give_item", "item_id": 37, "quantity": 1}, {"type": "give_item", "item_id": 35, "quantity": 1}, {"type": "give_item", "item_id": 46, "quantity": 2}, {"type": "give_item", "item_id": 47, "quantity": 1}, {"key": "ruins_dying_stranger.received_gift", "type": "set_flag", "bool_value": true}]', true) ON CONFLICT DO NOTHING;

INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (172, 661, 662, 2, 'ruins_dying_stranger.choice.leave', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (173, 662, 663, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;
INSERT INTO public.dialogue_edge OVERRIDING SYSTEM VALUE VALUES (174, 663, 669, 0, 'ruins_dying_stranger.choice.continue', NULL, NULL, false) ON CONFLICT DO NOTHING;

-- NPC dialogue links
INSERT INTO public.npc_dialogue VALUES (6, 7, 2, '[{"eq": true, "key": "ruins_dying_stranger.dialogue_started", "type": "flag"}, {"eq": true, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]') ON CONFLICT DO NOTHING;
INSERT INTO public.npc_dialogue VALUES (6, 8, 1, '[{"eq": true, "key": "ruins_dying_stranger.dialogue_started", "type": "flag"}, {"eq": false, "key": "ruins_dying_stranger.received_gift", "type": "flag"}]') ON CONFLICT DO NOTHING;
INSERT INTO public.npc_dialogue VALUES (6, 6, 0, NULL) ON CONFLICT DO NOTHING;

-- ============================================================================
-- SEQUENCE UPDATES
-- ============================================================================

SELECT pg_catalog.setval('public.items_id_seq', 75, true);
SELECT pg_catalog.setval('public.item_attributes_mapping_id_seq', 37, true);
SELECT pg_catalog.setval('public.item_use_effects_id_seq', 17, true);
SELECT pg_catalog.setval('public.mob_id_seq', 10, true);
SELECT pg_catalog.setval('public.mob_stat_id_seq', 423, true);
SELECT pg_catalog.setval('public.mob_loot_info_id_seq', 106, true);
SELECT pg_catalog.setval('public.mob_skills_id_seq', 13, true);
SELECT pg_catalog.setval('public.spawn_zones_zone_id_seq', 6, true);
SELECT pg_catalog.setval('public.spawn_zone_mobs_id_seq', 6, true);
SELECT pg_catalog.setval('public.quest_id_seq', 2, true);
SELECT pg_catalog.setval('public.quest_step_id_seq', 10, true);
SELECT pg_catalog.setval('public.quest_reward_id_seq', 6, true);
SELECT pg_catalog.setval('public.dialogue_id_seq', 8, true);
SELECT pg_catalog.setval('public.dialogue_node_id_seq', 699, true);
SELECT pg_catalog.setval('public.dialogue_edge_id_seq', 224, true);
SELECT pg_catalog.setval('public.vendor_inventory_id_seq', 92, true);
SELECT pg_catalog.setval('public.class_starter_items_id_seq', 2, true);

COMMIT;
