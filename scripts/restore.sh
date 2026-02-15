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

BACKUP_DIR="$SCRIPT_DIR/../backups"
POSTGRES_CONTAINER=${POSTGRES_CONTAINER:-urbanbook-postgres}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-UrbanBook}

# Determinar archivo de backup a restaurar
if [[ -n "${1:-}" ]]; then
	BACKUP_FILE="$1"
else
	# Usar el backup más reciente
	BACKUP_FILE=$(ls -t "$BACKUP_DIR"/urbanbook_db_*.sql 2>/dev/null | head -n 1)
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
	echo "Error: Archivo de backup no encontrado: $BACKUP_FILE"
	echo "Uso: $0 [ruta/al/backup.sql]"
	echo "      Si no se especifica, usa el backup mas reciente de $BACKUP_DIR"
	exit 1
fi

echo "========================================="
echo "Restauracion de Base de Datos"
echo "========================================="
echo "Backup: $BACKUP_FILE"
echo "Contenedor: $POSTGRES_CONTAINER"
echo "Base de datos: $POSTGRES_DB"
echo ""
read -p "Continuar? Esto ELIMINARA todos los datos actuales [y/N]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Cancelado."
	exit 0
fi

# Detener la API
echo "Deteniendo API..."
cd "$SCRIPT_DIR/.."
docker compose stop urbanbook-api

# Eliminar y recrear la base de datos
echo "Eliminando base de datos actual..."
docker exec -i "$POSTGRES_CONTAINER" dropdb -U "$POSTGRES_USER" --if-exists "$POSTGRES_DB"

echo "Creando base de datos..."
docker exec -i "$POSTGRES_CONTAINER" createdb -U "$POSTGRES_USER" "$POSTGRES_DB"

# Restaurar desde el backup
echo "Restaurando desde backup..."
docker exec -i "$POSTGRES_CONTAINER" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$BACKUP_FILE"

# Reiniciar la API
echo "Reiniciando API..."
docker compose start urbanbook-api

echo ""
echo "========================================="
echo "Restauracion completada exitosamente"
echo "========================================="
echo "Backup restaurado: $(basename "$BACKUP_FILE")"
