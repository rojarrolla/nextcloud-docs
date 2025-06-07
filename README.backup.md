# Nextcloud Server Configuration

## Server Information
- **Hostname**: nextcloud
- **IP Address**: 192.168.2.75
- **Domain**: vpn.cobanetworks.com
- **Ports**:
  - 80 (HTTP)
  - 443 (HTTPS)
  - 444 (HTTPS Alternative)

## User Accounts
- **Nextcloud Admin**:
  - Username: admin
  - Email: admin@cobanetworks.com

## Database Configuration
- **Type**: MariaDB
- **Database Name**: nextcloud
- **User**: nextcloud
- **Host**: localhost

## Directory Structure
- **Nextcloud Root**: /var/www/html/nextcloud
- **Data Directory**: /mnt/unraid_nextcloud/nextcloud_data
- **Backup Directory**: /mnt/unraid_nextcloud/backups

## Backup Configuration
- **Location**: /mnt/unraid_nextcloud/backups/YYYYMMDD/HHMMSS/
- **Frequency**: 4 times daily (00:00, 07:00, 12:00, 19:00)
- **Retention**: 7 days
- **Backup Contents**:
  - Database dump (nextcloud_db.sql)
  - Configuration files (nextcloud_config.tar.gz)
  - Full backup excluding data (nextcloud_full.tar.gz)

## SSL Configuration
- **Provider**: Let's Encrypt
- **Domain**: vpn.cobanetworks.com
- **Certificate Location**: /etc/letsencrypt/live/vpn.cobanetworks.com/
- **Auto-renewal**: Enabled

## Scripts de Backup y Restauración

### Script de Backup
- **Ubicación**: `/usr/local/bin/backup-nextcloud.sh`
- **Características**:
  - Crea backups diarios en formato YYYYMMDD/HHMMSS
  - Realiza backup de:
    - Base de datos (nextcloud_db.sql)
    - Archivos de configuración (nextcloud_config.tar.gz)
    - Backup completo excluyendo datos (nextcloud_full.tar.gz)
  - Ajusta permisos automáticamente
  - Limpia backups antiguos (más de 7 días)

### Script de Restauración
- **Ubicación**: `/usr/local/bin/restore-nextcloud.sh`
- **Características**:
  - Interfaz interactiva para seleccionar backup
  - Soporte para múltiples distribuciones Linux:
    - Ubuntu/Debian
    - CentOS/RHEL/Fedora
  - Restaura:
    - Base de datos
    - Archivos de configuración
    - Archivos de Nextcloud (excluyendo datos)
    - Certificados SSL
  - Configura automáticamente:
    - Apache/Nginx
    - MariaDB
    - Let's Encrypt
    - Montaje NFS a Unraid

### Uso del Script de Restauración
1. Copiar el script a la nueva VM:
   ```bash
   cp /mnt/unraid_nextcloud/backups/restore-nextcloud.sh /usr/local/bin/
   chmod +x /usr/local/bin/restore-nextcloud.sh
   ```

2. Ejecutar el script:
   ```bash
   sudo ./restore-nextcloud.sh
   ```

3. El script:
   - Detectará automáticamente la distribución Linux
   - Mostrará los backups disponibles
   - Permitirá seleccionar el backup a restaurar
   - Instalará y configurará todos los componentes necesarios
   - Restaurará los datos seleccionados

4. Verificar la instalación:
   - Acceder a https://vpn.cobanetworks.com:444
   - Verificar que los usuarios pueden acceder
   - Comprobar que los backups automáticos funcionan

## Maintenance Procedures
- **Backup Verification**: Daily
- **SSL Renewal**: Automatic (Let's Encrypt)
- **System Updates**: Weekly
- **Log Rotation**: Automatic

## Integration with Unraid
- **Share Name**: Nextcloud
- **Mount Point**: /mnt/unraid_nextcloud
- **Protocol**: NFS
- **Permissions**: www-data:www-data (33:33)

## Security Measures
- **Firewall**: UFW enabled
- **SSL**: Let's Encrypt certificates
- **File Permissions**: Strict (750 for directories, 640 for files)
- **User Isolation**: Enabled
- **Brute Force Protection**: Enabled

## Monitoring
- **Log Files**:
  - Nextcloud: /var/www/html/nextcloud/data/nextcloud.log
  - Apache: /var/log/apache2/error.log
  - Backup: /var/log/nextcloud-backup.log
  - Restore: /var/log/nextcloud-restore.log

## Troubleshooting
- **Common Issues**:
  - Permission problems: Check www-data ownership
  - SSL issues: Verify Let's Encrypt certificates
  - Backup failures: Check disk space and permissions
  - Restore issues: Verify backup integrity

## Recovery Procedures
1. **Full System Recovery**:
   - Use restore-nextcloud.sh script
   - Select appropriate backup
   - Follow interactive prompts

2. **Database Recovery**:
   - Use nextcloud_db.sql from backup
   - Restore using mysql command

3. **File Recovery**:
   - Use nextcloud_full.tar.gz from backup
   - Extract to /var/www/html/nextcloud

## Important Notes
- Always verify backup integrity before deletion
- Keep SSL certificates up to date
- Monitor disk space regularly
- Maintain proper file permissions
- Regular security updates
- Test restore procedures periodically

## Contacto y Soporte
- Documentación mantenida en GitHub: https://github.com/rojarrolla/nextcloud-docs

---
Última actualización: Mayo 2025 