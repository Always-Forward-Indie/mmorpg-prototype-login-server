#!/bin/bash
# dump_db.sh — Export content-only database dump from running Docker PostgreSQL.
# Strips: player accounts, characters, inventory, quest progress, analytics.
# Keeps:  all static game content (items, mobs, NPCs, quests, zones, skills, etc.)
#
# Usage:
#   ./tools/dump_db.sh                              # default container + default output
#   CONTAINER=my-db ./tools/dump_db.sh               # custom container name
#   ./tools/dump_db.sh --output path/to/dump.sql     # custom output path

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
DB_NAME="${DB_NAME:-mmo_prototype}"
DB_USER="${DB_USER:-postgres}"
CONTAINER="${CONTAINER:-mmorpg_prototype_db}"

# Default output: same location as current dump
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGIN_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT="${LOGIN_ROOT}/mmo_prototype_dump.sql"

# ── Parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --container) CONTAINER="$2"; shift 2 ;;
        --output|-o) OUTPUT="$2"; shift 2 ;;
        --db-name)   DB_NAME="$2"; shift 2 ;;
        --db-user)   DB_USER="$2"; shift 2 ;;
        --help|-h)
            echo "Usage: $0 [--container NAME] [--output FILE] [--db-name NAME] [--db-user USER]"
            echo ""
            echo "Exports the mmo_prototype database from a running Docker PostgreSQL container,"
            echo "stripping all player/account/analytics data while preserving game content."
            echo ""
            echo "Options:"
            echo "  --container NAME  Docker container name (default: $CONTAINER)"
            echo "  --output, -o FILE Output file path (default: $OUTPUT)"
            echo "  --db-name NAME    Database name (default: $DB_NAME)"
            echo "  --db-user USER    Database user (default: $DB_USER)"
            echo ""
            echo "Environment variables: CONTAINER, DB_NAME, DB_USER"
            exit 0
            ;;
        *) OUTPUT="$1"; shift ;;  # positional arg = output path
    esac
done

# ── Pre-flight checks ───────────────────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    echo "[ERROR] Container '$CONTAINER' is not running."
    echo "        Start it first: cd mmorpg-prototype-login-server && docker-compose up -d"
    exit 1
fi

echo "[INFO] Container : $CONTAINER"
echo "[INFO] Database  : $DB_NAME"
echo "[INFO] Output    : $OUTPUT"

# ── Player / analytics tables — schema only, no row data ───────────────────
# pg_dump --exclude-table-data dumps CREATE TABLE + indexes + constraints
# but omits the COPY block. The result is an empty table ready for new players.
EXCLUDE_DATA=(
    users user_sessions user_bans
    characters character_current_state character_position
    character_equipment character_skills character_emotes
    character_titles character_skill_bar character_skill_mastery
    character_reputation character_bestiary character_pity
    character_permanent_modifiers
    player_inventory player_quest player_active_effect
    player_flag player_skill_cooldown
    currency_transactions mob_active_effect
    game_analytics gm_action_log
)

EXCLUDE_ARGS=""
for table in "${EXCLUDE_DATA[@]}"; do
    EXCLUDE_ARGS+=" --exclude-table-data=$table"
done

# ── Dump schema + content ───────────────────────────────────────────────────
echo "[INFO] Dumping schema + content (excluding ${#EXCLUDE_DATA[@]} player tables) ..."

docker exec "$CONTAINER" \
    pg_dump -U "$DB_USER" -d "$DB_NAME" \
    --no-owner --no-acl \
    $EXCLUDE_ARGS \
    > "$OUTPUT"

# ── Reset runtime state in hybrid tables ───────────────────────────────────
# These tables contain both content and mutable runtime columns.
# Reset the runtime columns so the fresh DB starts in a clean state.
cat >> "$OUTPUT" <<'SQL'

-- ── Hybrid-table runtime state reset ──────────────────────────────────────
UPDATE public.timed_champion_templates SET next_spawn_at = NULL, last_killed_at = NULL;
UPDATE public.world_object_states SET state = 'active', depleted_at = NULL;
SQL

# ── Done ────────────────────────────────────────────────────────────────────
SIZE=$(wc -c < "$OUTPUT")
echo "[OK] Done — $SIZE bytes written to $OUTPUT"
echo "      Player data stripped. Content preserved. Ready for docker-entrypoint-initdb.d."
