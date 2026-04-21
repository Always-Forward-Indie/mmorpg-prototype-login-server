v0.1.12
21.04.2026
================
New:

**getCharactersList — слаги, пол и экипировка для превью.**
- Ответ теперь содержит `classSlug`, `raceSlug`, `genderSlug` вместо имён — локализация на стороне клиента.
- Поле `equipment` — массив `[{ "slotId": N, "itemSlug": "..." }]` с текущим снаряжением персонажа для отображения в экране выбора.
- `CharacterManager::getCharacterEquipmentPreview` — новый метод, получает экипировку через `character_equipment → player_inventory → items`.

**getCharacterCreationOptions — `slug` у гендеров.**
- Массив `genders` теперь возвращает поле `slug` (`"male"` / `"female"`) вместо `name`.

**createCharacter — джойн по slug.**
- SQL-запрос теперь находит класс/расу по `slug`, а не по `name` — клиент передаёт slug из `getCharacterCreationOptions`.

**DB — новый prepared statement.**
- `get_character_equipment_preview($char_id)` — `SELECT slot_id, item_slug FROM character_equipment JOIN player_inventory JOIN items WHERE character_id = $1`.

**DataStructs.hpp.**
- Добавлен `EquipmentPreviewItemStruct { slotId, itemSlug }`.
- `CharacterDataStruct` дополнен полем `characterGender` (slug) и вектором `equipment`.
- Порядок объявлений исправлен: `EquipmentPreviewItemStruct` объявлен до `CharacterDataStruct`.

Fixes:

**NetworkManager — критические баги чтения/записи.**
- Read loop больше не блокируется при неизвестном типе пакета: `startReadingFromClient` вызывается сразу после обработки сообщения, независимо от `sendResponse`.
- Защита от переполнения буфера: ранний выход если `message.length() >= max_length`.
- `catch` расширен с `nlohmann::json::parse_error` до `std::exception` — ASIO-поток больше не падает на `type_error` / `runtime_error`.

**EventHandler — зависание клиента на ошибке.**
- `handleRegisterAccountEvent` теперь отправляет `ERR_INTERNAL` клиенту при любом исключении вместо тихого выхода.

**AccountManager — ошибка компиляции.**
- Добавлен `#include <spdlog/logger.h>` (был forward-declared в `Logger.hpp`, вызывал ошибку при использовании в .cpp).

**Документация.**
- `docs/login-server-api.md` обновлена: `getCharactersList` — новые поля и `equipment`; `getCharacterCreationOptions` — `slug` у гендеров; `createCharacter` — поля теперь принимают slug.

---

v0.1.11
20.04.2026
================
New:

**Система регистрации аккаунта и полный цикл создания/удаления персонажа.**

**AccountManager — новый сервис регистрации аккаунтов.**
- `include/services/AccountManager.hpp` + `src/services/AccountManager.cpp` — метод `registerAccount(conn, clientData, login, password, email, ip, &outUserId, &outHash)`.
- Валидация: login `[A-Za-z0-9_]{3,20}`, password 8–100 символов, email (проверка на `@`).
- Хеширование пароля через OpenSSL EVP SHA-256 (TODO: migrate to argon2id перед продакшном).
- Дедупликация через `check_login_available` (case-insensitive).
- Создание сессии сразу после регистрации — клиент получает `clientId` + `hash` в одном ответе.
- Enum `AccountRegisterResult` с детализированными кодами ошибок.

**CharacterManager — усиленный `createCharacter`.**
- Валидация имени в C++ (regex `[A-Za-z ]{2,20}`, no double-spaces) до обращения к БД.
- Проверка лимита слотов (`MAX_CHARS_PER_ACCOUNT = 4`) через `get_character_slot_count`.
- Проверка уникальности имени через `check_character_name_exists` (case-insensitive).
- Выдача дефолтных скилов класса через `init_character_default_skills` (по `class_skill_tree.is_default = true`).
- Выдача стартовых предметов через `init_character_starter_items`.
- Enum `CharacterCreateResult` — конкретные коды ошибок вместо одного `0`.
- `deleteCharacter` — реализован: soft-delete с owner guard (UPDATE WHERE owner_id = accountId).

**Event System — новые типы событий.**
- `Event::REGISTER_ACCOUNT` — регистрация нового аккаунта.
- `Event::GET_CHARACTER_CREATION_OPTIONS` — получение списков классов/рас/полов.
- `EventData` variant расширен: добавлен `RegistrationDataStruct`.

**EventHandler — три новых обработчика.**
- `handleRegisterAccountEvent` — делегирует в `AccountManager`, возвращает `clientId` + `hash`.
- `handleGetCharacterCreationOptionsEvent` — три SQL-запроса в одной транзакции, возвращает массивы `classes`, `races`, `genders`.
- `handleDeleteCharacterEvent` — soft-delete с auth guard + owner guard.
- `handleCreateCharacterEvent` — обновлён: детализированные error-коды из `CharacterCreateResult`.

**NetworkManager — маршрутизация новых пакетов.**
- `registerAccount` → `Event::REGISTER_ACCOUNT` (без auth, IP берётся из socket).
- `getCharacterCreationOptions` → `Event::GET_CHARACTER_CREATION_OPTIONS` (требует hash).
- `deleteCharacter` → `Event::DELETE_CHARACTER` (требует hash + characterId).

**DB — Migration 068 — `class_starter_items`.**
- Таблица `class_starter_items`: `id`, `class_id` (FK → character_class), `item_id` (FK → items), `quantity`, `slot_index`, `durability_current` (NULL = из items.durability_max).
- Индекс `idx_class_starter_items_class`.
- Starter data: Mage → Wooden Staff + 50 Gold; Warrior → Iron Sword + Wooden Shield + 50 Gold.

**DB — новые prepared statements.**
- `check_login_available`, `register_user` — для регистрации аккаунта.
- `init_character_default_skills($char_id, $class_id)` — выдача дефолтных скилов.
- `init_character_starter_items($char_id, $class_id)` — выдача стартовых предметов.
- `check_character_name_exists`, `get_character_slot_count` — валидация при создании персонажа.
- `get_class_id_by_name` — разрешение class_id по имени.
- `delete_character($char_id, $account_id)` — soft-delete с owner guard.
- `get_character_classes`, `get_character_races`, `get_character_genders` — справочники для экрана создания.

**CMakeLists.txt.**
- Добавлен `src/services/AccountManager.cpp` в SOURCE_FILES.
- Добавлен `include/services/AccountManager.hpp` в HEADER_FILES.
- Подключён `OpenSSL::Crypto` для хеширования паролей.

**Документация.**
- `docs/login-server-api.md` — полная API-документация для разработчика клиента: все 7 endpoint'ов с примерами пакетов, таблицами полей, error-кодами и типовым flow.

**mmo_prototype_dump.sql** — обновлён (включает таблицу `class_starter_items`).

---

v0.1.10
18.04.2026
================
Fixes:

**DB — удалена устаревшая таблица `npc_position`.**
- `migrations/063_drop_npc_position.sql` — `DROP TABLE IF EXISTS public.npc_position`. `npc_placements` (migration 047) является единственным источником позиций NPC.
- `mmo_prototype_dump.sql` — удалены все секции `npc_position` (см. game-server changelog v0.2.5).

---

v0.1.9
18.04.2026
================
New:

**Migration 061 — Spawn Zone Shapes.**
- Тип `public.spawn_zone_shape` (ENUM: `'RECT'`, `'CIRCLE'`, `'ANNULUS'`) — создан на уровне БД, используется в обеих таблицах зон.
- Таблица `spawn_zones` — добавлены колонки: `shape_type spawn_zone_shape DEFAULT 'RECT'`, `center_x`, `center_y`, `inner_radius`, `outer_radius`. Существующие строки получили `center_x/y` из среднего AABB, `inner_radius=0`.
- Колонки `mob_id`, `max_mob_count`, `respawn_time_sec` вынесены в отдельную таблицу `spawn_zone_mobs` (нормализация: одна зона может содержать несколько видов мобов с разными настройками респауна).
- `COMMENT ON COLUMN` — полная документация всех новых колонок.

**Migration 062 — Game Zone Shapes.**
- Таблица `zones` — добавлены колонки: `shape_type spawn_zone_shape DEFAULT 'RECT'`, `center_x`, `center_y`, `inner_radius`, `outer_radius`. Существующие строки (village, fields) получили `center_x/y` из среднего AABB, `inner_radius=0`.
- `COMMENT ON COLUMN` — документация новых колонок.
- DB dump актуализирован: CREATE TABLE `zones` + `spawn_zones` содержат новые колонки; INSERT-строки обновлены.

---

v0.1.8
18.04.2026
================
New:

**Migration 059 — Stats System Overhaul.**
- Добавлены новые `entity_attributes`: `constitution` (id=27), `wisdom` (id=28), `agility` (id=29) — primary stats; `fire_resistance` (30), `ice_resistance` (31), `nature_resistance` (32), `arcane_resistance` (33), `holy_resistance` (34), `shadow_resistance` (35) — элементальные резисты.
- Удалены dead/некорректные атрибуты с каскадной очисткой всех FK таблиц (`class_stat_formula`, `character_permanent_modifiers`, `mob_stat`, `item_attributes_mapping`, `item_set_bonuses`, `status_effect_modifiers`, `player_active_effect`, `mob_active_effect`, `npc_attributes`, `skill_effects_mapping`): `luck` (id=5), `heal_on_use` (21), `hunger_restore` (22), `physical_resistance` (23), `magical_resistance` (24), `parry_chance` (26).
- `class_stat_formula` — полный пересчёт для Mage (class_id=1) и Warrior (class_id=2) по новой системе статов с учётом `constitution`, `wisdom`, `agility` и всех elemental resistances. Формула: `stat = base_value + multiplier × level^exponent`.
- `character_permanent_modifiers` — удалены строки для удалённых атрибутов.
- `mob_stat` — удалены строки для удалённых атрибутов.
- `crit_multiplier` унифицирован: значение теперь хранится как % (`200 = x2.0`) во всех таблицах.
- `game_config` — добавлены ключи: `combat.default_crit_multiplier=200` (% семантика), `combat.crit_chance_cap=75`, `combat.block_chance_cap=75`, `combat.attack_speed_base_divisor=100`, `combat.cast_speed_base_divisor=100`.

**Migration 060 — Clean permanent modifiers, prune mobs, rebalance mob_stat.**
- `character_permanent_modifiers` — `TRUNCATE`: игроки теперь получают базовые статы исключительно из `class_stat_formula`; перманентные модификаторы не используются для базовых значений.
- Удалены мобы `id IN (6, 7, 8)` (WolfPackLeader, OldWolf, ForestGoblin) и все их FK данные: `mob_stat`, `mob_skills`, `mob_loot_info`, `mob_position`, `mob_resistances`, `mob_weaknesses`, `spawn_zone_mobs`, `mob_active_effect`, `character_bestiary`, `timed_champion_templates`, `zone_event_templates`.
- `mob_stat` для SmallFox (id=1, lvl1) и GreyWolf (id=2, lvl1) — полный перебаланс: Fox ~40 HP / 6 phys_atk, Wolf ~80 HP / 10 phys_atk. `crit_multiplier=200` (новая % семантика). Все ссылки на удалённые атрибуты очищены.
- DB dump актуализирован.

---

v0.1.7
17.04.2026
================
New:

**Migration 058 — таблица игровой аналитики.**
- Таблица `game_analytics` — лог игровых событий для анализа плейтеста: `id` (BIGSERIAL PK), `event_type` (VARCHAR 64, NOT NULL), `character_id` (INT, FK → characters ON DELETE SET NULL), `session_id` (VARCHAR 64), `level` (SMALLINT), `zone_id` (INT), `payload` (JSONB DEFAULT '{}'), `created_at` (TIMESTAMPTZ DEFAULT now()).
- Индексы: `idx_game_analytics_type_time` (event_type, created_at DESC), `idx_game_analytics_char_time` (character_id, created_at DESC), `idx_game_analytics_session` (session_id), `idx_game_analytics_created` (created_at DESC), `idx_game_analytics_payload` (GIN on payload).
- DB dump актуализирован.

---

v0.1.6
16.04.2026
================
New:

**Migration 043 — World Interactive Objects.**
- Таблица `world_objects` — статические определения объектов: `id`, `slug` (UNIQUE), `name_key`, `object_type` (CHECK: examine/search/activate/use_with_item/channeled), `scope` (CHECK: per_player/global), `pos_x/y/z`, `rot_z`, `zone_id` (FK → zones), `dialogue_id` (FK → dialogue), `loot_table_id` (INT, no FK — synthetic mob_id для loot engine), `required_item_id` (FK → items), `interaction_radius`, `channel_time_sec`, `respawn_sec`, `is_active_by_default`, `min_level`, `condition_group` (JSONB, same schema as dialogue conditions). Колонки `mesh_id` и `notes` в таблицу не включены: mesh binding выполняется в UE5 по `slug`, notes — dev-поле без runtime-значения.
- Таблица `world_object_states` — персистированное runtime-состояние глобальных объектов: `object_id` (PK + FK → world_objects CASCADE DELETE), `state` (CHECK: active/depleted/disabled), `depleted_at` (TIMESTAMPTZ). Per-player состояние хранится в `player_flags` по ключу `wio_interacted_<objectId>`.
- Индексы: `idx_world_objects_zone` (zone_id), `idx_world_object_states_state` (state WHERE state != 'active').
- Полные `COMMENT ON TABLE` и `COMMENT ON COLUMN` аннотации для обеих таблиц (19 комментариев).
- DB dump актуализирован.

---

v0.1.5
17.04.2026
================
New:

**Migration 042 — Data-driven система выдачи титулов.**
- `title_definitions` — добавлена колонка `condition_params JSONB NOT NULL DEFAULT '{}'`. Структура JSONB зависит от `earn_condition`: `bestiary`, `mastery`, `reputation`, `level`, `quest`.
- 4 плацехолдерных титула заменены 12 настоящими дата-драйвен титулами (3 bestiary + 3 mastery + 3 reputation + 2 level + 1 quest).
- DB dump актуализирован: `title_definitions` содержит новую колонку, `setval` обновлён до 12.

---

v0.1.4
11.04.2026
================
Improvements:
DB dump (mmo_prototype_dump.sql) — добавлены `COMMENT ON TABLE` и `COMMENT ON COLUMN` аннотации для таблиц `character_bestiary` (описание назначения таблицы, полей `character_id`, `mob_template_id`, `kill_count`), `character_pity` (pity-механика редких дропов, поля `character_id`, `item_id`, `kill_count`), `character_reputation` (фракционная репутация, смысл положительных/отрицательных значений).

---

v0.1.3
08.04.2026
================
Improvements:
DB dump (mmo_prototype_dump.sql) актуализирован: обновлены и добавлены строки `skill_properties_mapping` для свойств `cast_ms` и `swing_ms` у всех активных скилов: `basic_attack` cast_ms 100→1000, swing_ms 1100→1200; `shield_bash` cast_ms 0→1000, swing_ms 800→1100; `whirlwind` cast_ms 0→1000, swing_ms 1000→1200; добавлены отсутствующие записи swing_ms для `power_slash` (2300), `fireball` (4500), `frost_bolt` (2300), `arcane_blast` (3500), `chain_lightning` (3000). Сиквенс `skills_attributes_mapping_id_seq` обновлён с 43 до 50.

---

v0.1.2
05.04.2026
================
Improvements:
DB dump (mmo_prototype_dump.sql) updated to current schema and test data:
  - New ENUM types added: `effect_modifier_type`, `node_type`, `quest_state`, `quest_step_type`, `status_effect_category`.
  - New trigger function `game_config_set_updated_at()` for automatic `updated_at` stamping on the game_config table.
  - New tables: `character_permanent_modifiers` (with full column comments), `entity_attributes` (global attribute registry with comments), `character_bestiary`, `character_class`, `character_current_state` (with `current_health`, `current_mana`, `is_dead`, `updated_at` comments), `character_equipment` (with `id`, `character_id`, `equip_slot_id`, `inventory_item_id`, `equipped_at` comments), `character_genders`, `character_pity`, `character_skill_mastery`, `character_reputation`.
  - `character_position` updated: added `rot_z` float column (with comment) and corresponding sequence. `character_position_id_seq` recreated.
  - `character_skills` updated: added `current_level` column (with comment); sequences `character_skills_id_seq1` recreated.
  - `characters` updated: added `radius` and `free_skill_points` columns (with comments).
  - Sequence values updated to reflect latest test data: `character_equipment_id_seq`, `player_active_effect_id_seq`, `player_inventory_id_seq`, `user_sessions_id_seq`, `character_attributes_id_seq`, `character_attributes_id_seq1`.
config.json — minor host binding update.

---

v0.1.1
21.03.2026
================
Improvements:
DB dump (mmo_prototype_dump.sql) updated with current test data:
  - character_bestiary: added kill count records for characters 2 and 3 (mob templates 1 and 2).
  - character_current_state: updated HP/mana snapshots for characters.
  - player_active_effect: 180+ new active effect rows added.
  - user_sessions: new test sessions added.
  - Updated sequence counters: character_equipment_id_seq→26, player_active_effect_id_seq→340, player_inventory_id_seq→174, user_sessions_id_seq→528.

---

v0.1.0
15.03.2026
================
New:
DB dump (mmo_prototype_dump.sql) updated with 23 new tables: character_bestiary, character_pity, character_reputation, character_skill_mastery, damage_elements, factions, item_class_restrictions, item_set_bonuses, item_set_members, item_sets, item_use_effects, mastery_definitions, mob_resistances, mob_weaknesses, passive_skill_modifiers, player_active_effect, respawn_zones, skill_damage_formulas (replaced skill_effects), skill_damage_types (replaced skill_effects_type), status_effect_modifiers, status_effects, timed_champion_templates, zone_event_templates.
New DB enum types: effect_modifier_type, node_type, quest_state, quest_step_type, status_effect_category.

Bug Fixes:
NetworkManager — fixed critical bug: global static accumulation buffer replaced with per-socket buffer map (socketBuffers_, protected by socketBufferMutex_). Previous implementation shared one buffer across all client connections, causing data corruption under concurrent load.
NetworkManager — fixed concurrent read loop: startReadingFromClient() is no longer called inside the read completion handler, preventing two simultaneous async reads on the same socket.
NetworkManager — socket cleanup on disconnect now erases the per-socket buffer from the map before closing (all disconnect paths: EOF, operation_aborted, and other errors).
NetworkManager — socket close now uses the non-throwing error_code overload to avoid uncaught exceptions during teardown.

---

v0.0.3
07.03.2026
================
New:
Per-subsystem logging via spdlog — each component (auth, db, network, events, character, gameloop) now logs to its own named channel. Each subsystem level can be set independently via environment variables (LOG_LEVEL_<NAME>).
DatabasePool — new connection pool for the database.
Added TimestampUtils utility.
31 new DB migrations: item system refactor, mob stat formulas, active effects, resistances, DoT/HoT effects, AoE skills, mob AI config, mob social behaviour, loot tables, experience levels, spawn zones, and more.

Improvements:
Database — major refactor, improved reliability and query structure.
EventHandler — extended, new event types added.
Authenticator — reworked.
CharacterManager — improved character data handling.
JSONParser — updated.
DB dump (mmo_prototype_dump.sql) updated to current state.
Dockerfile — added spdlog dependencies.
docker-compose: LOG_LEVEL=info by default; network, gameloop, events set to warn to reduce log noise.

---

v0.0.2
28.02.2026
================
New:
Add changelog file to track changes and updates in the project.
Improvements:
Update and improve DB schema.