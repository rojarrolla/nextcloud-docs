#!/bin/bash

# Configuración
BACKUP_BASE_DIR="/mnt/unraid_nextcloud/backups"
NEXTCLOUD_DIR="/var/www/html/nextcloud"
DB_USER="nextcloud"
DB_PASS="NextCloud2025!"
DB_NAME="nextcloud"
LOG_FILE="/var/log/nextcloud-restore.log"
UNRAID_IP="192.168.2.75"
UNRAID_SHARE="Nextcloud"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para detectar la distribución
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)
    elif [ -f /etc/redhat-release ]; then
        DISTRO="centos"
        VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        log "Error: No se pudo detectar la distribución"
        exit 1
    fi
    log "Distribución detectada: $DISTRO $VERSION"
}

# Función para instalar dependencias según la distribución
install_dependencies() {
    log "Instalando dependencias para $DISTRO..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get update
            apt-get install -y apache2 mariadb-server php php-mysql php-gd php-curl \
                php-mbstring php-intl php-xml php-zip php-bcmath php-gmp php-imagick \
                nfs-common certbot python3-certbot-apache
            ;;
        centos|rhel|fedora)
            yum update -y
            yum install -y httpd mariadb-server php php-mysqlnd php-gd php-curl \
                php-mbstring php-intl php-xml php-zip php-bcmath php-gmp php-imagick \
                nfs-utils certbot python3-certbot-apache
            ;;
        *)
            log "Error: Distribución no soportada: $DISTRO"
            exit 1
            ;;
    esac
}

# Función para configurar MariaDB según la distribución
configure_mariadb() {
    log "Configurando MariaDB..."
    
    case $DISTRO in
        ubuntu|debian)
            systemctl start mariadb
            systemctl enable mariadb
            ;;
        centos|rhel|fedora)
            systemctl start mariadb
            systemctl enable mariadb
            ;;
    esac
    
    mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
    mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
}

# Función para configurar Apache según la distribución
configure_apache() {
    log "Configurando Apache..."
    
    case $DISTRO in
        ubuntu|debian)
            a2enmod rewrite
            a2enmod headers
            a2enmod env
            a2enmod dir
            a2enmod mime
            a2enmod ssl
            systemctl restart apache2
            ;;
        centos|rhel|fedora)
            # En CentOS/RHEL los módulos vienen habilitados por defecto
            systemctl restart httpd
            ;;
    esac
}

# Función para configurar el montaje NFS
configure_nfs() {
    log "Configurando montaje NFS..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get install -y nfs-common
            ;;
        centos|rhel|fedora)
            yum install -y nfs-utils
            ;;
    esac
    
    mkdir -p /mnt/unraid_nextcloud
    echo "${UNRAID_IP}:/mnt/user/${UNRAID_SHARE} /mnt/unraid_nextcloud nfs defaults 0 0" >> /etc/fstab
    mount -a
}

# Función para configurar Let's Encrypt
configure_letsencrypt() {
    log "Configurando Let's Encrypt..."
    
    case $DISTRO in
        ubuntu|debian)
            certbot --apache -d vpn.cobanetworks.com --non-interactive --agree-tos --email admin@cobanetworks.com
            ;;
        centos|rhel|fedora)
            certbot --apache -d vpn.cobanetworks.com --non-interactive --agree-tos --email admin@cobanetworks.com
            ;;
    esac
}

# Función para mostrar backups disponibles
show_available_backups() {
    echo "Backups disponibles:"
    echo "-------------------"
    
    # Obtener lista de directorios de backup
    local backup_dirs=($(find "$BACKUP_BASE_DIR" -maxdepth 2 -type d -name "[0-9]*" | sort -r))
    
    if [ ${#backup_dirs[@]} -eq 0 ]; then
        echo "No se encontraron backups disponibles en $BACKUP_BASE_DIR"
        exit 1
    fi
    
    # Mostrar backups con número
    local i=1
    for dir in "${backup_dirs[@]}"; do
        local date=$(basename "$(dirname "$dir")")
        local time=$(basename "$dir")
        local size=$(du -sh "$dir" | cut -f1)
        printf "%2d) %s %s (Tamaño: %s)\n" $i "$date" "$time" "$size"
        ((i++))
    done
    
    # Pedir selección
    echo
    read -p "Seleccione el número del backup a restaurar (1-${#backup_dirs[@]}): " selection
    
    # Validar selección
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#backup_dirs[@]} ]; then
        echo "Selección inválida"
        exit 1
    fi
    
    # Obtener directorio seleccionado
    local selected_dir="${backup_dirs[$((selection-1))]}"
    BACKUP_DATE=$(basename "$(dirname "$selected_dir")")
    BACKUP_TIME=$(basename "$selected_dir")
    BACKUP_DIR="$selected_dir"
    
    echo "Backup seleccionado: $BACKUP_DATE $BACKUP_TIME"
    echo "Ubicación: $BACKUP_DIR"
    echo
    read -p "¿Desea continuar con la restauración? (s/n): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        echo "Restauración cancelada"
        exit 0
    fi
}

# Verificar que existan los archivos de backup
verify_backup_files() {
    DB_BACKUP="${BACKUP_DIR}/nextcloud_db.sql"
    CONFIG_BACKUP="${BACKUP_DIR}/nextcloud_config.tar.gz"
    FULL_BACKUP="${BACKUP_DIR}/nextcloud_full.tar.gz"

    if [ ! -f "$DB_BACKUP" ]; then
        log "Error: No se encontró el backup de la base de datos"
        exit 1
    fi

    if [ ! -f "$CONFIG_BACKUP" ]; then
        log "Error: No se encontró el backup de configuración"
        exit 1
    fi

    if [ ! -f "$FULL_BACKUP" ]; then
        log "Error: No se encontró el backup completo"
        exit 1
    fi
}

# Detectar distribución
detect_distro

# Mostrar backups disponibles y obtener selección
show_available_backups

# Verificar archivos de backup
verify_backup_files

log "Iniciando restauración desde backups del ${BACKUP_DATE} ${BACKUP_TIME}"

# 1. Instalar dependencias
install_dependencies

# 2. Configurar MariaDB
configure_mariadb

# 3. Configurar Apache
configure_apache

# 4. Montar Unraid
configure_nfs

# 5. Restaurar la base de datos
log "Restaurando base de datos..."
mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$DB_BACKUP"

# 6. Restaurar configuración
log "Restaurando configuración..."
tar -xzf "$CONFIG_BACKUP" -C /

# 7. Restaurar archivos de Nextcloud (excluyendo data)
log "Restaurando archivos de Nextcloud..."
mkdir -p "$NEXTCLOUD_DIR"
tar -xzf "$FULL_BACKUP" -C /

# 8. Configurar Let's Encrypt
configure_letsencrypt

# 9. Instalar scripts de backup
log "Instalando scripts de backup..."
cp /usr/local/bin/backup-nextcloud.sh /usr/local/bin/backup-nextcloud.sh.bak
cp /usr/local/bin/restore-nextcloud.sh /usr/local/bin/restore-nextcloud.sh.bak

cat > /usr/local/bin/backup-nextcloud.sh << 'EOF'
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
EOF

chmod +x /usr/local/bin/backup-nextcloud.sh

# 10. Configurar cron para backups
log "Configurando cron para backups..."
cat > /etc/cron.d/nextcloud-backups << EOF
0 0 * * * root /usr/local/bin/backup-nextcloud.sh
0 7 * * * root /usr/local/bin/backup-nextcloud.sh
0 12 * * * root /usr/local/bin/backup-nextcloud.sh
0 19 * * * root /usr/local/bin/backup-nextcloud.sh
EOF

# 11. Ajustar permisos
log "Ajustando permisos..."
chown -R www-data:www-data "$NEXTCLOUD_DIR"
find "$NEXTCLOUD_DIR" -type d -exec chmod 750 {} \;
find "$NEXTCLOUD_DIR" -type f -exec chmod 640 {} \;

# 12. Reiniciar servicios
log "Reiniciando servicios..."
case $DISTRO in
    ubuntu|debian)
        systemctl restart apache2
        systemctl restart mariadb
        ;;
    centos|rhel|fedora)
        systemctl restart httpd
        systemctl restart mariadb
        ;;
esac

log "Restauración completada exitosamente"
log "Por favor, verifica que todo funcione correctamente accediendo a https://vpn.cobanetworks.com:444"
