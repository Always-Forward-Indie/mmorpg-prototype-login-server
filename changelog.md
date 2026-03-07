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