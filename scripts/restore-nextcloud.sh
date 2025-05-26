#!/bin/bash

# Cargar configuración
if [ -f "/etc/nextcloud/backup.conf" ]; then
    source "/etc/nextcloud/backup.conf"
else
    echo "Error: Archivo de configuración no encontrado"
    exit 1
fi

# Verificar si se proporcionó la fecha del backup
if [ -z "$1" ]; then
    echo "Uso: $0 YYYYMMDD"
    echo "Ejemplo: $0 20240315"
    exit 1
fi

BACKUP_DATE=$1
BACKUP_DIR="/var/backups/nextcloud"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
CONFIG_DIR="/etc/apache2"
SSL_DIR="/etc/ssl"
LETSENCRYPT_DIR="/etc/letsencrypt"

# Verificar que existan los archivos de backup
DB_BACKUP="$BACKUP_DIR/nextcloud_db_$BACKUP_DATE.sql"
FULL_BACKUP=$(find "$BACKUP_DIR" -name "nextcloud_full_${BACKUP_DATE}_*.tar.gz" | sort -r | head -n 1)

if [ ! -f "$DB_BACKUP" ]; then
    echo "Error: No se encontró el backup de la base de datos para la fecha $BACKUP_DATE"
    exit 1
fi

if [ -z "$FULL_BACKUP" ]; then
    echo "Error: No se encontró el backup completo para la fecha $BACKUP_DATE"
    exit 1
fi

echo "Iniciando restauración desde backups del $BACKUP_DATE"
echo "Backup de base de datos: $DB_BACKUP"
echo "Backup completo: $FULL_BACKUP"

# Crear directorios necesarios
echo "Creando directorios necesarios..."
sudo mkdir -p "$NEXTCLOUD_DIR"
sudo mkdir -p "$CONFIG_DIR/sites-available"
sudo mkdir -p "$SSL_DIR/certs"
sudo mkdir -p "$SSL_DIR/private"
sudo mkdir -p "$LETSENCRYPT_DIR/live"

# Restaurar la base de datos
echo "Restaurando base de datos..."
sudo mysql --defaults-extra-file=/etc/nextcloud/mysql.cnf "$DB_NAME" < "$DB_BACKUP"

# Restaurar archivos
echo "Restaurando archivos..."
sudo tar -xzf "$FULL_BACKUP" -C /

# Ajustar permisos
echo "Ajustando permisos..."
sudo chown -R www-data:www-data "$NEXTCLOUD_DIR"
sudo chmod -R 750 "$NEXTCLOUD_DIR"
sudo find "$NEXTCLOUD_DIR" -type f -exec chmod 640 {} \;

# Reiniciar servicios
echo "Reiniciando servicios..."
sudo systemctl restart apache2
sudo systemctl restart mysql

echo "Restauración completada. Por favor, verifica que todo funcione correctamente."
echo "Puedes verificar el estado de Nextcloud con: sudo -u www-data php $NEXTCLOUD_DIR/occ status" 