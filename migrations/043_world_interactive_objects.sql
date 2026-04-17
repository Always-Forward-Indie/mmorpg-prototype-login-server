-- Migration 043: World Interactive Objects (WIO)
-- Adds static definitions and per-instance global state for world objects.
-- Per-player state (examine / channeled) is stored in existing player_flags table.

-- ============================================================
-- world_objects — static definition table
-- Loaded by game-server on startup and pushed to chunk-server
-- as SET_ALL_WORLD_OBJECTS. Analogous to the npc_templates table.
-- Mesh binding is done client-side in UE5 by slug — mesh_id is NOT stored.
-- ============================================================
CREATE TABLE IF NOT EXISTS world_objects (
    id                  SERIAL PRIMARY KEY,
    slug                VARCHAR(128) NOT NULL UNIQUE,
    name_key            VARCHAR(128) NOT NULL,
    object_type         VARCHAR(32)  NOT NULL
                          CHECK (object_type IN ('examine','search','activate','use_with_item','channeled')),
    scope               VARCHAR(16)  NOT NULL DEFAULT 'per_player'
                          CHECK (scope IN ('per_player','global')),
    pos_x               FLOAT        NOT NULL DEFAULT 0,
    pos_y               FLOAT        NOT NULL DEFAULT 0,
    pos_z               FLOAT        NOT NULL DEFAULT 0,
    rot_z               FLOAT        NOT NULL DEFAULT 0,
    zone_id             INT          REFERENCES zones(id)      ON DELETE SET NULL,
    dialogue_id         INT          REFERENCES dialogue(id)   ON DELETE SET NULL,
    loot_table_id       INT          NULL,
    required_item_id    INT          REFERENCES items(id)      ON DELETE SET NULL,
    interaction_radius  FLOAT        NOT NULL DEFAULT 250,
    channel_time_sec    INT          NOT NULL DEFAULT 0,
    respawn_sec         INT          NOT NULL DEFAULT 0,
    is_active_by_default BOOLEAN     NOT NULL DEFAULT TRUE,
    min_level           INT          NOT NULL DEFAULT 0,
    condition_group     JSONB        NOT NULL DEFAULT 'null'::jsonb
);

COMMENT ON TABLE world_objects IS 'Static definitions of world interactive objects (WIO). Mesh binding is performed in UE5 by slug — no mesh_id column. Loaded by game-server at startup and forwarded to chunk-server.';
COMMENT ON COLUMN world_objects.id                  IS 'Primary key, auto-incremented.';
COMMENT ON COLUMN world_objects.slug                IS 'Unique machine-readable identifier. UE5 uses this to look up the static mesh / blueprint asset at runtime.';
COMMENT ON COLUMN world_objects.name_key            IS 'Localisation key forwarded to the client (e.g. wio.forest_tracks_01.name).';
COMMENT ON COLUMN world_objects.object_type         IS 'Interaction type: examine | search | activate | use_with_item | channeled.';
COMMENT ON COLUMN world_objects.scope               IS 'State scope: per_player (stored in player_flags) or global (stored in world_object_states).';
COMMENT ON COLUMN world_objects.pos_x               IS 'World X position (Unreal Engine units).';
COMMENT ON COLUMN world_objects.pos_y               IS 'World Y position.';
COMMENT ON COLUMN world_objects.pos_z               IS 'World Z position.';
COMMENT ON COLUMN world_objects.rot_z               IS 'Yaw rotation around Z axis (degrees).';
COMMENT ON COLUMN world_objects.zone_id             IS 'FK to zones.id. Determines which chunk-server zone owns this object. NULL = global / not zone-specific.';
COMMENT ON COLUMN world_objects.dialogue_id         IS 'FK to dialogue.id. Dialogue tree opened on interaction. NULL = no dialogue.';
COMMENT ON COLUMN world_objects.loot_table_id       IS 'Synthetic mob_id used as a key into mob_loot_info for drop generation. NULL = no loot. No FK by design.';
COMMENT ON COLUMN world_objects.required_item_id    IS 'FK to items.id. Item the player must possess to interact (use_with_item type). NULL = no requirement.';
COMMENT ON COLUMN world_objects.interaction_radius  IS 'Max distance (UE units) from which a player can trigger interaction.';
COMMENT ON COLUMN world_objects.channel_time_sec    IS 'Channeling duration in seconds. 0 = instant interaction.';
COMMENT ON COLUMN world_objects.respawn_sec         IS 'Time in seconds before the object resets after depletion. 0 = never respawns (permanent or one-shot).';
COMMENT ON COLUMN world_objects.is_active_by_default IS 'Initial enabled state when no persistent state row exists yet.';
COMMENT ON COLUMN world_objects.min_level           IS 'Minimum character level required to interact. 0 = no restriction.';
COMMENT ON COLUMN world_objects.condition_group     IS 'JSONB condition tree evaluated before allowing interaction (same schema as dialogue conditions). null = always allowed.';

-- ============================================================
-- world_object_states — persisted global runtime state
-- Only rows for objects with scope='global' are stored here.
-- Per-player state lives in player_flags as 'wio_interacted_<objectId>'.
-- ============================================================
CREATE TABLE IF NOT EXISTS world_object_states (
    object_id           INT          PRIMARY KEY REFERENCES world_objects(id) ON DELETE CASCADE,
    state               VARCHAR(16)  NOT NULL DEFAULT 'active'
                          CHECK (state IN ('active','depleted','disabled')),
    depleted_at         TIMESTAMPTZ  NULL
);

COMMENT ON TABLE world_object_states IS 'Persisted runtime state for global-scope world objects. One row per object that has ever been depleted or disabled. Per-player state is stored in player_flags (key: wio_interacted_<objectId>).';
COMMENT ON COLUMN world_object_states.object_id   IS 'FK to world_objects.id (PK + cascade delete).';
COMMENT ON COLUMN world_object_states.state       IS 'Current runtime state: active | depleted | disabled.';
COMMENT ON COLUMN world_object_states.depleted_at IS 'Timestamp when the object was last depleted. Used by the respawn timer. NULL if never depleted.';

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_world_objects_zone          ON world_objects(zone_id);
CREATE INDEX IF NOT EXISTS idx_world_objects_type_scope    ON world_objects(object_type, scope);
CREATE INDEX IF NOT EXISTS idx_world_object_states_state   ON world_object_states(state);

-- ============================================================
-- quest_steps extension: interact type support
-- QuestStepStruct already has a generic 'params' JSONB field in code;
-- we store object_id and required_count there for 'interact' steps.
-- No schema change needed if quest_steps.params is already JSONB.
-- If the column does not exist yet, add it:
-- ============================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_name = 'quest_step' AND column_name = 'params'
    ) THEN
        ALTER TABLE quest_step ADD COLUMN params JSONB NOT NULL DEFAULT '{}'::jsonb;
    END IF;
END$$;

-- Example world object rows for testing (commented out — fill in with real data via seeds):
-- INSERT INTO world_objects (slug, name_key, object_type, scope, pos_x, pos_y, pos_z, zone_id, dialogue_id, interaction_radius)
-- VALUES
--   ('forest_tracks_01', 'wio.forest_tracks_01.name', 'examine', 'per_player', 1200.0, 3400.0, 0.0, 1, 5, 300),
--   ('old_barrel_01',    'wio.old_barrel_01.name',    'search',  'global',     800.0,  2100.0, 0.0, 1, NULL, 250);
