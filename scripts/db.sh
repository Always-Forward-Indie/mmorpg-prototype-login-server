#!/bin/bash
# db.sh — Unified database management tool for MMORPG prototype.
#
# Commands:
#   dump            Export content-only dump (no player data)
#   load            Full destructive load (DROP DATABASE + recreate + import)
#   load-safe       Load content while preserving existing players & analytics
#   backup-players  Export player data only (for manual backup)
#
# Usage (non-interactive):
#   ./scripts/db.sh dump [--output FILE] [--container NAME] ...
#   ./scripts/db.sh load [--file FILE] [--yes] ...
#   ./scripts/db.sh load-safe [--file FILE] [--yes] ...
#   ./scripts/db.sh backup-players [--output FILE] ...
#
# Usage (interactive):
#   ./scripts/db.sh
#
# Environment variables: CONTAINER, DB_NAME, DB_USER

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
DB_NAME="${DB_NAME:-mmo_prototype}"
DB_USER="${DB_USER:-postgres}"
CONTAINER="${CONTAINER:-mmorpg_prototype_db}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGIN_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_DUMP="${LOGIN_ROOT}/mmo_prototype_dump.sql"
DEFAULT_PLAYER_BACKUP="${LOGIN_ROOT}/mmo_prototype_players_backup.sql"

FORCE=false

# ── Tables ──────────────────────────────────────────────────────────────────
# Tables excluded from content dumps (player/account/analytics data)
PLAYER_TABLES=(
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

# Sequences owned by player tables (reset after player data restore)
PLAYER_SEQUENCES=(
    character_emotes_id_seq
    character_equipment_id_seq
    character_skills_id_seq1
    currency_transactions_id_seq
    game_analytics_id_seq
    gm_action_log_id_seq
    player_active_effect_id_seq
    user_bans_id_seq
    user_sessions_id_seq
)

# ── Helpers ─────────────────────────────────────────────────────────────────

die() { echo "[ERROR] $*" >&2; exit 1; }
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
ok() { echo "[OK] $*"; }

check_container() {
    if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
        die "Container '$CONTAINER' is not running. Start it first: cd mmorpg-prototype-login-server && docker-compose up -d"
    fi
}

confirm() {
    local msg="${1:-Proceed? This action is destructive.}"
    if [ "$FORCE" = true ]; then
        return 0
    fi
    echo ""
    warn "$msg"
    echo ""
    read -r -p "Proceed? [y/N] " REPLY
    if [ "${REPLY,,}" != "y" ] && [ "$REPLY" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
}

# ── dump ────────────────────────────────────────────────────────────────────

cmd_dump() {
    local output="$DEFAULT_DUMP"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --container) CONTAINER="$2"; shift 2 ;;
            --output|-o) output="$2"; shift 2 ;;
            --db-name)   DB_NAME="$2"; shift 2 ;;
            --db-user)   DB_USER="$2"; shift 2 ;;
            *) output="$1"; shift ;;
        esac
    done

    check_container

    info "Container : $CONTAINER"
    info "Database  : $DB_NAME"
    info "Output    : $output"

    local exclude_args=""
    for table in "${PLAYER_TABLES[@]}"; do
        exclude_args+=" --exclude-table-data=$table"
    done

    info "Dumping schema + content (excluding ${#PLAYER_TABLES[@]} player tables) ..."

    docker exec "$CONTAINER" \
        pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --no-owner --no-acl \
        $exclude_args \
        > "$output"

    # Reset runtime state in hybrid tables
    cat >> "$output" <<'SQL'

-- ── Hybrid-table runtime state reset ──────────────────────────────────────
UPDATE public.timed_champion_templates SET next_spawn_at = NULL, last_killed_at = NULL;
UPDATE public.world_object_states SET state = 'active', depleted_at = NULL;
SQL

    local size
    size=$(wc -c < "$output")
    ok "Done — $size bytes written to $output"
    echo "      Player data stripped. Content preserved. Ready for docker-entrypoint-initdb.d."
}

# ── load ────────────────────────────────────────────────────────────────────

cmd_load() {
    local dump_file="$DEFAULT_DUMP"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --container) CONTAINER="$2"; shift 2 ;;
            --file|-f)   dump_file="$2"; shift 2 ;;
            --db-name)   DB_NAME="$2"; shift 2 ;;
            --db-user)   DB_USER="$2"; shift 2 ;;
            --yes|-y)    FORCE=true; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    check_container

    if [ ! -f "$dump_file" ]; then
        die "Dump file not found: $dump_file"
    fi

    info "Container : $CONTAINER"
    info "Database  : $DB_NAME"
    info "Dump file : $dump_file ($(wc -c < "$dump_file") bytes)"

    confirm "This will DROP database '$DB_NAME' and recreate it. ALL DATA will be permanently lost."

    info "Dropping database '$DB_NAME' ..."
    docker exec "$CONTAINER" psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS \"$DB_NAME\" WITH (FORCE);" 2>&1

    info "Creating database '$DB_NAME' ..."
    docker exec "$CONTAINER" psql -U "$DB_USER" -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\";" 2>&1

    info "Loading dump ($(wc -c < "$dump_file") bytes) ..."
    docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -f - < "$dump_file" 2>&1

    echo ""
    ok "Database '$DB_NAME' restored from $dump_file"
}

# ── load-safe ───────────────────────────────────────────────────────────────

cmd_load_safe() {
    local dump_file="$DEFAULT_DUMP"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --container) CONTAINER="$2"; shift 2 ;;
            --file|-f)   dump_file="$2"; shift 2 ;;
            --db-name)   DB_NAME="$2"; shift 2 ;;
            --db-user)   DB_USER="$2"; shift 2 ;;
            --yes|-y)    FORCE=true; shift ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done

    check_container

    if [ ! -f "$dump_file" ]; then
        die "Dump file not found: $dump_file"
    fi

    local player_backup
    player_backup="/tmp/mmorpg_player_backup_$$.sql"

    # Cleanup temp file on exit
    trap 'rm -f "$player_backup"' EXIT

    info "Container     : $CONTAINER"
    info "Database      : $DB_NAME"
    info "Dump file     : $dump_file ($(wc -c < "$dump_file") bytes)"
    info "Player backup : $player_backup (temporary)"

    confirm "This will DROP database '$DB_NAME', reload content from dump, then RESTORE existing players, stats & analytics. Game data will be replaced."

    # ── Step 1: Backup player data ──────────────────────────────────────────
    info "Backing up player data (${#PLAYER_TABLES[@]} tables) ..."

    local table_args=""
    for table in "${PLAYER_TABLES[@]}"; do
        table_args+=" --table=$table"
    done

    docker exec "$CONTAINER" \
        pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --data-only \
        $table_args \
        > "$player_backup"

    local backup_size
    backup_size=$(wc -c < "$player_backup")
    info "Player backup size: $backup_size bytes"

    if [ "$backup_size" -eq 0 ]; then
        warn "Player backup is empty — no player data exists. Continuing with load only."
    fi

    # ── Step 2: Drop + recreate + load main dump ────────────────────────────
    info "Dropping database '$DB_NAME' ..."
    docker exec "$CONTAINER" psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS \"$DB_NAME\" WITH (FORCE);" 2>&1

    info "Creating database '$DB_NAME' ..."
    docker exec "$CONTAINER" psql -U "$DB_USER" -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\";" 2>&1

    info "Loading content dump ($(wc -c < "$dump_file") bytes) ..."
    docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -f - < "$dump_file" 2>&1

    # ── Step 3: Restore player data ─────────────────────────────────────────
    if [ "$backup_size" -gt 0 ]; then
        info "Restoring player data ..."
        docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -f - < "$player_backup" 2>&1 || {
            warn "Player data restore failed! The database has content but no players."
            warn "Check the backup file: $player_backup"
            trap - EXIT
            exit 1
        }

        # ── Step 4: Reset sequences for player tables ───────────────────────
        info "Resetting sequences ..."
        local seq_sql=""
        for seq in "${PLAYER_SEQUENCES[@]}"; do
            # Extract base table name: "character_emotes_id_seq" -> "character_emotes"
            # Handle special cases like "character_skills_id_seq1"
            local table_name
            table_name=$(echo "$seq" | sed -E 's/_id_seq[0-9]*$//')
            seq_sql+="SELECT setval('$seq', COALESCE((SELECT MAX(id) FROM $table_name), 1));"
        done

        docker exec "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "$seq_sql" 2>&1 > /dev/null
    fi

    rm -f "$player_backup"
    trap - EXIT

    echo ""
    ok "Database '$DB_NAME' reloaded — content from '$dump_file', players preserved."
}

# ── backup-players ──────────────────────────────────────────────────────────

cmd_backup_players() {
    local output="$DEFAULT_PLAYER_BACKUP"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --container) CONTAINER="$2"; shift 2 ;;
            --output|-o) output="$2"; shift 2 ;;
            --db-name)   DB_NAME="$2"; shift 2 ;;
            --db-user)   DB_USER="$2"; shift 2 ;;
            *) output="$1"; shift ;;
        esac
    done

    check_container

    info "Container : $CONTAINER"
    info "Database  : $DB_NAME"
    info "Output    : $output"

    local table_args=""
    for table in "${PLAYER_TABLES[@]}"; do
        table_args+=" --table=$table"
    done

    info "Exporting player data (${#PLAYER_TABLES[@]} tables) with data ..."

    docker exec "$CONTAINER" \
        pg_dump -U "$DB_USER" -d "$DB_NAME" \
        --no-owner --no-acl \
        $table_args \
        > "$output"

    local size
    size=$(wc -c < "$output")
    ok "Done — $size bytes written to $output"
    echo "      Contains full schema + data for all player/account/analytics tables."
}

# ── Interactive menu ────────────────────────────────────────────────────────

interactive_menu() {
    echo ""
    echo "=== MMORPG Database Tool ==="
    echo ""
    echo "  1) dump            Export content-only dump (no player data)"
    echo "  2) load            Full destructive load (DROP + recreate + import)"
    echo "  3) load-safe       Load content, preserve existing players & analytics"
    echo "  4) backup-players  Export player data only (for manual backup)"
    echo ""
    echo "  h) help            Show detailed help"
    echo "  q) quit"
    echo ""

    read -r -p "Select command [1-4/h/q]: " CHOICE

    case "$CHOICE" in
        1|dump)
            shift 2>/dev/null || true
            ask_dump_options
            cmd_dump "${DUMP_OPTS[@]}"
            ;;
        2|load)
            ask_load_options
            cmd_load "${LOAD_OPTS[@]}"
            ;;
        3|load-safe)
            ask_load_options "load-safe"
            cmd_load_safe "${LOAD_OPTS[@]}"
            ;;
        4|backup-players)
            ask_backup_options
            cmd_backup_players "${BACKUP_OPTS[@]}"
            ;;
        h|help)
            show_help
            interactive_menu
            ;;
        q|quit|exit)
            echo "Bye."
            exit 0
            ;;
        *)
            echo "Invalid choice: $CHOICE"
            interactive_menu
            ;;
    esac
}

ask_dump_options() {
    DUMP_OPTS=()
    read -r -p "Output file [$DEFAULT_DUMP]: " val
    DUMP_OPTS+=(--output "${val:-$DEFAULT_DUMP}")
    read -r -p "Container name [$CONTAINER]: " val
    [ -n "$val" ] && DUMP_OPTS+=(--container "$val")
    read -r -p "Database name [$DB_NAME]: " val
    [ -n "$val" ] && DUMP_OPTS+=(--db-name "$val")
}

ask_load_options() {
    local mode="${1:-load}"
    LOAD_OPTS=()
    read -r -p "Dump file to load [$DEFAULT_DUMP]: " val
    LOAD_OPTS+=(--file "${val:-$DEFAULT_DUMP}")
    read -r -p "Container name [$CONTAINER]: " val
    [ -n "$val" ] && LOAD_OPTS+=(--container "$val")
    read -r -p "Database name [$DB_NAME]: " val
    [ -n "$val" ] && LOAD_OPTS+=(--db-name "$val")
    if [ "$mode" = "load-safe" ]; then
        read -r -p "Skip confirmation? [y/N]: " val
        [ "${val,,}" = "y" ] && LOAD_OPTS+=(--yes)
    else
        read -r -p "Skip confirmation? [y/N]: " val
        [ "${val,,}" = "y" ] && LOAD_OPTS+=(--yes)
    fi
}

ask_backup_options() {
    BACKUP_OPTS=()
    read -r -p "Output file [$DEFAULT_PLAYER_BACKUP]: " val
    BACKUP_OPTS+=(--output "${val:-$DEFAULT_PLAYER_BACKUP}")
    read -r -p "Container name [$CONTAINER]: " val
    [ -n "$val" ] && BACKUP_OPTS+=(--container "$val")
}

show_help() {
    echo ""
    echo "MMORPG Database Tool — help"
    echo "==========================="
    echo ""
    echo "Commands:"
    echo ""
    echo "  dump [options]"
    echo "    Export content-only database dump (schema + game content)."
    echo "    Excludes player accounts, characters, inventory, quests, analytics."
    echo "    Options: --output FILE, --container NAME, --db-name NAME, --db-user USER"
    echo ""
    echo "  load [options]"
    echo "    Full destructive load: DROP DATABASE, recreate, import SQL dump."
    echo "    ALL DATA is permanently lost."
    echo "    Options: --file FILE, --container NAME, --yes, --db-name NAME, --db-user USER"
    echo ""
    echo "  load-safe [options]"
    echo "    Load content dump while PRESERVING existing player accounts, characters,"
    echo "    inventory, quest progress, analytics, and all player-related data."
    echo "    Steps: backup players → drop DB → load dump → restore players → reset sequences."
    echo "    Options: --file FILE, --container NAME, --yes, --db-name NAME, --db-user USER"
    echo ""
    echo "  backup-players [options]"
    echo "    Export player-related tables (${#PLAYER_TABLES[@]} tables) with full data."
    echo "    Useful for manual backups before major operations."
    echo "    Options: --output FILE, --container NAME, --db-name NAME, --db-user USER"
    echo ""
    echo "Environment variables: CONTAINER, DB_NAME, DB_USER"
    echo ""
}

# ── Main ────────────────────────────────────────────────────────────────────

case "${1:-}" in
    dump)
        shift
        cmd_dump "$@"
        ;;
    load)
        shift
        cmd_load "$@"
        ;;
    load-safe)
        shift
        cmd_load_safe "$@"
        ;;
    backup-players)
        shift
        cmd_backup_players "$@"
        ;;
    --help|-h|help)
        show_help
        ;;
    "")
        # No arguments — interactive mode
        interactive_menu
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: $0 {dump|load|load-safe|backup-players|help}"
        echo "       Run without arguments for interactive mode."
        exit 1
        ;;
esac
