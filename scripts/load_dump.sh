#!/bin/bash
# load_dump.sh — Restore a database dump into a running Docker PostgreSQL container.
# Drops and recreates the database, then loads the SQL dump.
#
# Usage:
#   ./tools/load_dump.sh                          # default container + default dump
#   ./tools/load_dump.sh --file path/to/dump.sql   # custom dump file
#   CONTAINER=my-db ./tools/load_dump.sh           # custom container name
#
# WARNING: Destructive — drops the database and all its data.
#          Stop game-server and chunk-server before running.

set -euo pipefail

# ── Defaults ────────────────────────────────────────────────────────────────
DB_NAME="${DB_NAME:-mmo_prototype}"
DB_USER="${DB_USER:-postgres}"
CONTAINER="${CONTAINER:-mmorpg_prototype_db}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGIN_ROOT="$(dirname "$SCRIPT_DIR")"
DUMP_FILE="${LOGIN_ROOT}/mmo_prototype_dump.sql"

FORCE=false

# ── Parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --container) CONTAINER="$2"; shift 2 ;;
        --file|-f)   DUMP_FILE="$2"; shift 2 ;;
        --db-name)   DB_NAME="$2"; shift 2 ;;
        --db-user)   DB_USER="$2"; shift 2 ;;
        --yes|-y)    FORCE=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--container NAME] [--file FILE] [--yes]"
            echo ""
            echo "Drops and recreates the database from a SQL dump file."
            echo "Game-server and chunk-server must be stopped."
            echo ""
            echo "Options:"
            echo "  --container NAME  Docker container name (default: $CONTAINER)"
            echo "  --file, -f FILE   SQL dump to load (default: $DUMP_FILE)"
            echo "  --db-name NAME    Database name (default: $DB_NAME)"
            echo "  --db-user USER    Database user (default: $DB_USER)"
            echo "  --yes, -y         Skip confirmation prompt"
            echo ""
            echo "Environment variables: CONTAINER, DB_NAME, DB_USER"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── Pre-flight checks ───────────────────────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
    echo "[ERROR] Container '$CONTAINER' is not running."
    echo "        Start it first: cd mmorpg-prototype-login-server && docker-compose up -d"
    exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
    echo "[ERROR] Dump file not found: $DUMP_FILE"
    exit 1
fi

echo "[INFO] Container : $CONTAINER"
echo "[INFO] Database  : $DB_NAME"
echo "[INFO] Dump file : $DUMP_FILE ($(wc -c < "$DUMP_FILE") bytes)"

# ── Check active connections ────────────────────────────────────────────────
ACTIVE=$(docker exec "$CONTAINER" psql -U "$DB_USER" -tAc \
    "SELECT count(*) FROM pg_stat_activity WHERE datname='$DB_NAME' AND pid <> pg_backend_pid();" 2>/dev/null || echo "0")
if [ "$ACTIVE" -gt 0 ] 2>/dev/null; then
    echo "[ERROR] $ACTIVE active connection(s) to '$DB_NAME'."
    echo "        Stop game-server and chunk-server first:"
    echo "          cd mmorpg-prototype-game-server && docker-compose down"
    echo "          cd mmorpg-prototype-chunk-server-new && docker-compose down"
    exit 1
fi

# ── Confirmation ────────────────────────────────────────────────────────────
echo ""
echo "[WARN] This will DROP database '$DB_NAME' and recreate it."
echo "       All data in the database will be permanently lost."
echo ""

if [ "$FORCE" = false ]; then
    read -r -p "Proceed? [y/N] " CONFIRM
    if [ "${CONFIRM,,}" != "y" ] && [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# ── Drop + recreate + load ──────────────────────────────────────────────────
echo "[INFO] Dropping database '$DB_NAME' ..."
docker exec "$CONTAINER" psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS \"$DB_NAME\";" 2>&1

echo "[INFO] Creating database '$DB_NAME' ..."
docker exec "$CONTAINER" psql -U "$DB_USER" -c "CREATE DATABASE \"$DB_NAME\" OWNER \"$DB_USER\";" 2>&1

echo "[INFO] Loading dump ($(wc -c < "$DUMP_FILE") bytes) ..."
docker exec -i "$CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -f - < "$DUMP_FILE" 2>&1

echo ""
echo "[OK] Database '$DB_NAME' restored from $DUMP_FILE"
