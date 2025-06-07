#!/bin/bash

# Configuración
BACKUP_BASE_DIR="/mnt/unraid_nextcloud/backups"
DATE=$(date +%Y%m%d)
TIME=$(date +%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/${DATE}/${TIME}"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
DB_USER="nextcloud"
DB_PASS="NextCloud2025!"
DB_NAME="nextcloud"
LOG_FILE="/var/log/nextcloud-backup.log"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Crear directorio de backup
mkdir -p "$BACKUP_DIR"
chown www-data:www-data "$BACKUP_DIR"
chmod 750 "$BACKUP_DIR"

log "Iniciando backup en $BACKUP_DIR"

# Backup de la base de datos
log "Realizando backup de la base de datos..."
DB_BACKUP="${BACKUP_DIR}/nextcloud_db.sql"
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$DB_BACKUP"
chown www-data:www-data "$DB_BACKUP"
chmod 640 "$DB_BACKUP"

# Backup de la configuración
log "Realizando backup de la configuración..."
CONFIG_BACKUP="${BACKUP_DIR}/nextcloud_config.tar.gz"
tar -czf "$CONFIG_BACKUP" \
    "${NEXTCLOUD_DIR}/config" \
    "${NEXTCLOUD_DIR}/themes" \
    "${NEXTCLOUD_DIR}/apps" \
    /etc/apache2/sites-available/nextcloud*.conf \
    /etc/ssl/certs/nextcloud-selfsigned.crt \
    /etc/ssl/private/nextcloud-selfsigned.key \
    /etc/letsencrypt/live/
chown www-data:www-data "$CONFIG_BACKUP"
chmod 640 "$CONFIG_BACKUP"

# Backup completo (excluyendo datos de Unraid)
log "Realizando backup completo..."
FULL_BACKUP="${BACKUP_DIR}/nextcloud_full.tar.gz"
tar -czf "$FULL_BACKUP" \
    --exclude="${NEXTCLOUD_DIR}/data" \
    --exclude="${NEXTCLOUD_DIR}/config" \
    --exclude="${NEXTCLOUD_DIR}/themes" \
    --exclude="${NEXTCLOUD_DIR}/apps" \
    "$NEXTCLOUD_DIR"
chown www-data:www-data "$FULL_BACKUP"
chmod 640 "$FULL_BACKUP"

# Limpieza de backups antiguos (mantener solo 7 días)
log "Limpiando backups antiguos..."
find "$BACKUP_BASE_DIR" -type d -mtime +7 -exec rm -rf {} \;

log "Backup completado exitosamente"
