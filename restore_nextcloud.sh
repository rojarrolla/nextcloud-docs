#!/bin/bash

# Script de restauración para Nextcloud
# Restaura todos los componentes desde un backup completo

# Verificar argumentos
if [ $# -ne 1 ]; then
    echo "Uso: $0 <fecha_del_backup>"
    echo "Ejemplo: $0 20240417_0700"
    exit 1
fi

# Configuración
BACKUP_DIR="/mnt/unraid_nextcloud/backups/nextcloud"
BACKUP_DATE="$1"
BACKUP_NAME="nextcloud_backup_${BACKUP_DATE}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}_full.tar.gz"
TEMP_DIR="/tmp/nextcloud_restore_${BACKUP_DATE}"
LOG_FILE="/var/log/nextcloud-restore.log"
MYSQL_CNF="/etc/nextcloud/mysql.cnf"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
APACHE_CONF_DIR="/etc/apache2/sites-available"
SSL_CERT_DIR="/etc/ssl/certs"
SSL_KEY_DIR="/etc/ssl/private"
LETSENCRYPT_DIR="/etc/letsencrypt"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verificar que el backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    log "ERROR: No se encontró el archivo de backup $BACKUP_FILE"
    exit 1
fi

# Crear directorio temporal
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Extraer el backup
log "Extrayendo archivo de backup"
tar -xzf "$BACKUP_FILE"
if [ $? -ne 0 ]; then
    log "ERROR: Falló la extracción del backup"
    exit 1
fi

# Restaurar base de datos
log "Restaurando base de datos"
mysql --defaults-file="$MYSQL_CNF" nextcloud < "${BACKUP_NAME}_db.sql"
if [ $? -ne 0 ]; then
    log "ERROR: Falló la restauración de la base de datos"
    exit 1
fi

# Restaurar configuración de Nextcloud
log "Restaurando configuración de Nextcloud"
tar -xzf "${BACKUP_NAME}_config.tar.gz" -C /
if [ $? -ne 0 ]; then
    log "ERROR: Falló la restauración de la configuración"
    exit 1
fi

# Restaurar certificados SSL
log "Restaurando certificados SSL"
tar -xzf "${BACKUP_NAME}_ssl.tar.gz" -C /
if [ $? -ne 0 ]; then
    log "ERROR: Falló la restauración de los certificados SSL"
    exit 1
fi

# Restaurar configuración de Apache
log "Restaurando configuración de Apache"
tar -xzf "${BACKUP_NAME}_apache.tar.gz" -C /
if [ $? -ne 0 ]; then
    log "ERROR: Falló la restauración de la configuración de Apache"
    exit 1
fi

# Restaurar datos
log "Restaurando datos"
tar -xzf "${BACKUP_NAME}_data.tar.gz" -C /
if [ $? -ne 0 ]; then
    log "ERROR: Falló la restauración de los datos"
    exit 1
fi

# Ajustar permisos
log "Ajustando permisos"
chown -R www-data:www-data "$NEXTCLOUD_DIR"
find "$NEXTCLOUD_DIR" -type d -exec chmod 750 {} \;
find "$NEXTCLOUD_DIR" -type f -exec chmod 640 {} \;

# Reiniciar servicios
log "Reiniciando servicios"
systemctl restart apache2
systemctl restart php8.2-fpm

# Limpiar
log "Limpiando archivos temporales"
rm -rf "$TEMP_DIR"

log "Restauración completada exitosamente"
exit 0 