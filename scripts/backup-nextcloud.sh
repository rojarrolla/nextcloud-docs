#!/bin/bash

# Cargar configuración
if [ -f "/etc/nextcloud/backup.conf" ]; then
    source "/etc/nextcloud/backup.conf"
else
    echo "Error: Archivo de configuración no encontrado"
    exit 1
fi

# Configuración
BACKUP_DIR="/var/backups/nextcloud"
DATE=$(date +%Y%m%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
NEXTCLOUD_DIR="/var/www/html/nextcloud"
CONFIG_DIR="/etc/apache2"
SSL_DIR="/etc/ssl"
LETSENCRYPT_DIR="/etc/letsencrypt"
RETENTION_DAYS=30

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Backup de la base de datos
echo "Iniciando backup de la base de datos..."
mysqldump --defaults-extra-file=/etc/nextcloud/mysql.cnf "$DB_NAME" > "$BACKUP_DIR/nextcloud_db_$DATE.sql"

# Backup de archivos de configuración y datos
echo "Iniciando backup de archivos..."
tar -czf "$BACKUP_DIR/nextcloud_full_$TIMESTAMP.tar.gz" \
    "$NEXTCLOUD_DIR/config" \
    "$CONFIG_DIR/sites-available" \
    "$SSL_DIR/certs/nextcloud-selfsigned.crt" \
    "$SSL_DIR/private/nextcloud-selfsigned.key" \
    "$LETSENCRYPT_DIR/live" \
    "$NEXTCLOUD_DIR/data"

# Limpiar backups antiguos
echo "Limpiando backups antiguos..."
find "$BACKUP_DIR" -name "nextcloud_*" -type f -mtime +$RETENTION_DAYS -delete

echo "Backup completado: $TIMESTAMP" 