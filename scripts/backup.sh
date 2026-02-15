#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	. "$ENV_FILE"
	set +a
fi

DATE=$(date +"%Y%m%d_%H%M")
BACKUP_DIR="$SCRIPT_DIR/../backups"
mkdir -p "$BACKUP_DIR"

POSTGRES_CONTAINER=${POSTGRES_CONTAINER:-urbanbook-postgres}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-UrbanBook}

docker exec -t "$POSTGRES_CONTAINER" pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
	> "$BACKUP_DIR/urbanbook_db_${DATE}.sql"

# Mantener solo los últimos 5 backups
ls -t "$BACKUP_DIR"/urbanbook_db_*.sql 2>/dev/null | tail -n +6 | xargs -r rm -f

echo "Backup completado: urbanbook_db_${DATE}.sql"
