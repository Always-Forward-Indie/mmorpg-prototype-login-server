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