#!/bin/bash

# Script de backup para Nextcloud
# Incluye: base de datos, archivos de configuración, certificados SSL y datos

# Configuración
BACKUP_DIR="/mnt/unraid_nextcloud/backups/nextcloud"
DATE=$(date +%Y%m%d_%H%M)
BACKUP_NAME="nextcloud_backup_$DATE"
LOG_FILE="/var/log/nextcloud-backup.log"
MYSQL_CNF="/etc/nextcloud/mysql.cnf"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
DATA_DIR="/mnt/unraid_nextcloud/data"
APACHE_CONF_DIR="/etc/apache2/sites-available"
SSL_CERT_DIR="/etc/ssl/certs"
SSL_KEY_DIR="/etc/ssl/private"
LETSENCRYPT_DIR="/etc/letsencrypt"

# Crear directorio de backup si no existe
mkdir -p "$BACKUP_DIR"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Iniciar backup
log "Iniciando backup de Nextcloud"

# Backup de la base de datos
log "Realizando backup de la base de datos"
mysqldump --defaults-file="$MYSQL_CNF" nextcloud > "$BACKUP_DIR/${BACKUP_NAME}_db.sql"
if [ $? -eq 0 ]; then
    log "Backup de base de datos completado"
else
    log "ERROR: Falló el backup de la base de datos"
    exit 1
fi

# Backup de archivos de configuración de Nextcloud
log "Realizando backup de archivos de configuración"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" \
    "$NEXTCLOUD_DIR/config" \
    "$NEXTCLOUD_DIR/.htaccess" \
    "$NEXTCLOUD_DIR/.user.ini"

# Backup de certificados SSL
log "Realizando backup de certificados SSL"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_ssl.tar.gz" \
    "$SSL_CERT_DIR/nextcloud-selfsigned.crt" \
    "$SSL_KEY_DIR/nextcloud-selfsigned.key" \
    "$LETSENCRYPT_DIR"

# Backup de configuración de Apache
log "Realizando backup de configuración de Apache"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_apache.tar.gz" \
    "$APACHE_CONF_DIR/nextcloud.conf" \
    "$APACHE_CONF_DIR/nextcloud-ssl.conf" \
    "/etc/apache2/ports.conf"

# Backup de datos (excluyendo archivos montados en Unraid)
log "Realizando backup de datos"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_data.tar.gz" \
    --exclude="$DATA_DIR" \
    "$NEXTCLOUD_DIR"

# Crear archivo de manifiesto
log "Creando archivo de manifiesto"
cat > "$BACKUP_DIR/${BACKUP_NAME}_manifest.txt" << EOF
Backup de Nextcloud - $DATE
Contenido:
1. Base de datos: ${BACKUP_NAME}_db.sql
2. Configuración: ${BACKUP_NAME}_config.tar.gz
3. Certificados SSL: ${BACKUP_NAME}_ssl.tar.gz
4. Configuración Apache: ${BACKUP_NAME}_apache.tar.gz
5. Datos: ${BACKUP_NAME}_data.tar.gz

Notas:
- Los datos montados en Unraid (/mnt/unraid_nextcloud/data) están excluidos
- Los certificados Let's Encrypt están incluidos
- La configuración de Apache incluye los virtualhosts y puertos
- Ubicación del backup: $BACKUP_DIR
EOF

# Comprimir todo en un solo archivo
log "Comprimiendo todos los archivos de backup"
tar -czf "$BACKUP_DIR/${BACKUP_NAME}_full.tar.gz" \
    -C "$BACKUP_DIR" \
    "${BACKUP_NAME}_db.sql" \
    "${BACKUP_NAME}_config.tar.gz" \
    "${BACKUP_NAME}_ssl.tar.gz" \
    "${BACKUP_NAME}_apache.tar.gz" \
    "${BACKUP_NAME}_data.tar.gz" \
    "${BACKUP_NAME}_manifest.txt"

# Limpiar archivos individuales
log "Limpiando archivos temporales"
rm -f "$BACKUP_DIR/${BACKUP_NAME}_db.sql" \
      "$BACKUP_DIR/${BACKUP_NAME}_config.tar.gz" \
      "$BACKUP_DIR/${BACKUP_NAME}_ssl.tar.gz" \
      "$BACKUP_DIR/${BACKUP_NAME}_apache.tar.gz" \
      "$BACKUP_DIR/${BACKUP_NAME}_data.tar.gz" \
      "$BACKUP_DIR/${BACKUP_NAME}_manifest.txt"

# Mantener solo los últimos 21 backups (7 días × 3 backups por día)
log "Limpiando backups antiguos"
ls -t "$BACKUP_DIR"/nextcloud_backup_*_full.tar.gz | tail -n +22 | xargs -r rm

log "Backup completado exitosamente"
exit 0 