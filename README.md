# Documentación del Servidor Nextcloud

## Información General
- **Servidor**: VM en ESXi
- **Sistema Operativo**: Ubuntu Server
- **Dominio**: vpn.cobanetworks.com
- **Gateway**: 192.168.2.1

## Configuración de Puertos
- **HTTP**: 7086 (redirige automáticamente a HTTPS)
- **HTTPS**: 444
- **Base de datos**: MariaDB en puerto por defecto (3306)

## Configuración de Apache
- Sitio configurado para usar SSL con certificado autofirmado
- VirtualHost configurado para los puertos 7086 (HTTP) y 444 (HTTPS)
- Redirección automática de HTTP a HTTPS

### Archivos de Configuración Importantes
- Configuración SSL: `/etc/apache2/sites-available/nextcloud-ssl.conf`
- Configuración HTTP: `/etc/apache2/sites-available/nextcloud.conf`
- Puertos: `/etc/apache2/ports.conf`

## Usuarios y Grupos
### Usuarios Configurados
- nextadmin (administrador)
- Rodrigo (administrador, username: rod)
- Ahernandez
- Manolo

### Grupos
- admin: Rodrigo, nextadmin
- Users: Ahernandez, Manolo

## Base de Datos
- **Tipo**: MariaDB
- **Usuario DB**: nextcloud
- **Contraseña DB**: NextCloud2025!
- **Base de datos**: nextcloud
- **Ubicación backups**: /var/backups/nextcloud/

## Directorios Importantes
- **Instalación Nextcloud**: /var/www/html/nextcloud
- **Datos**: /mnt/unraid_nextcloud/data
- **Configuración**: /var/www/html/nextcloud/config
- **Logs Apache**: /var/log/apache2/

## Certificados SSL
- **Certificado**: Let's Encrypt (Certbot)
- **Ubicación**: /etc/letsencrypt/live/vpn.cobanetworks.com/
  - fullchain.pem: Certificado completo
  - privkey.pem: Llave privada
  - chain.pem: Certificado intermedio
  - cert.pem: Certificado del servidor
- **Renovación**: Automática mediante Certbot
- **Configuración Apache**: Los certificados están configurados en el VirtualHost HTTPS (puerto 444)

## Configuración de Seguridad
- Forzado de HTTPS
- Certificado SSL autofirmado
- Firewall UFW activo
- Acceso restringido por IP a panel de administración

## Mantenimiento
### Backups
- Respaldos automáticos que incluyen:
  - Base de datos MariaDB
  - Archivos de configuración de Nextcloud
  - Certificados SSL (Let's Encrypt)
  - Archivos de configuración de Apache
  - Datos de Nextcloud
- **Horarios de backup**:
  - 00:00 (medianoche)
  - 07:00 (mañana)
  - 12:00 (mediodía)
  - 19:00 (noche)
- **Ubicación**: /mnt/unraid_nextcloud/backups/YYYYMMDD/HHMMSS/
- **Retención**: Se mantienen los backups de los últimos 7 días
- **Logs**: /var/log/nextcloud-backup.log

### Scripts de Backup y Restauración
#### Ubicación de los Scripts
- Script de backup: `/usr/local/bin/backup-nextcloud.sh`
- Script de restauración: `/usr/local/bin/restore-nextcloud.sh`
- Configuración de cron: `/etc/cron.d/nextcloud-backups`
- Log de backup: `/var/log/nextcloud-backup.log`
- Log de restauración: `/var/log/nextcloud-restore.log`

#### Características del Script de Backup
- Crea una carpeta por día y hora con formato YYYYMMDD/HHMMSS
- Realiza tres tipos de backup:
  - Base de datos MariaDB (nextcloud_db.sql)
  - Archivos de configuración (nextcloud_config.tar.gz)
  - Backup completo (nextcloud_full.tar.gz)
- Mantiene backups de los últimos 7 días
- Registra todas las operaciones en el log
- Ajusta permisos automáticamente (www-data:www-data)

#### Características del Script de Restauración
- Interfaz interactiva que muestra los backups disponibles
- Muestra fecha, hora y tamaño de cada backup
- Permite seleccionar el backup a restaurar
- Requiere confirmación antes de proceder
- Instala y configura todo el entorno necesario:
  - Apache, MariaDB, PHP y dependencias
  - Let's Encrypt y Certbot
  - Montaje NFS con Unraid
  - Scripts de backup
  - Configuración de cron
- Restaura:
  - Base de datos
  - Configuración de Nextcloud
  - Archivos de Nextcloud (excluyendo data)
  - Certificados SSL
- Ajusta permisos automáticamente
- Reinicia servicios necesarios

#### Uso del Script de Restauración
1. Copiar el script a la nueva VM:
   ```bash
   cp /mnt/unraid_nextcloud/backups/restore-nextcloud.sh /usr/local/bin/
   chmod +x /usr/local/bin/restore-nextcloud.sh
   ```

2. Ejecutar el script como root:
   ```bash
   sudo ./restore-nextcloud.sh
   ```

3. Seguir las instrucciones en pantalla:
   - Seleccionar el backup a restaurar
   - Confirmar la restauración
   - Esperar a que se complete el proceso

4. Verificar la instalación:
   - Acceder a https://vpn.cobanetworks.com:444
   - Verificar que los datos se hayan restaurado correctamente
   - Comprobar que los backups automáticos estén configurados

#### Estado Actual del Sistema
- **Backups**: Los backups se almacenan en `/mnt/unraid_nextcloud/backups/YYYYMMDD/HHMMSS/`
- **Scripts**: Los scripts están instalados en `/usr/local/bin/`
- **Cron**: Configurado para ejecutar backups tres veces al día
- **Logs**: Los logs se mantienen en `/var/log/`

#### Pasos de Instalación y Configuración
1. **Preparación del Servidor Unraid**:
   ```bash
   # En el servidor Unraid
   - Crear el compartido "Nextcloud"
   - Configurar permisos del compartido
   - Crear la carpeta "backups" dentro del compartido
   ```

2. **Configuración del Montaje**:
   ```bash
   # En el servidor Nextcloud
   sudo mkdir -p /mnt/unraid_nextcloud
   sudo mount -t nfs 192.168.2.75:/mnt/user/Nextcloud /mnt/unraid_nextcloud
   
   # Para montaje automático, añadir a /etc/fstab:
   192.168.2.75:/mnt/user/Nextcloud /mnt/unraid_nextcloud nfs defaults 0 0
   ```

3. **Instalación de los Scripts**:
   ```bash
   # Copiar los scripts a su ubicación final
   sudo cp /home/rod/nextcloud-docs/scripts/backup-nextcloud.sh /usr/local/bin/
   sudo cp /home/rod/nextcloud-docs/scripts/restore-nextcloud.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/backup-nextcloud.sh /usr/local/bin/restore-nextcloud.sh
   ```

4. **Configuración de Cron**:
   ```bash
   # Crear archivo de cron
   sudo nano /etc/cron.d/nextcloud-backups
   
   # Añadir las siguientes líneas:
   30 7 * * * root /usr/local/bin/backup-nextcloud.sh
   0 12 * * * root /usr/local/bin/backup-nextcloud.sh
   30 19 * * * root /usr/local/bin/backup-nextcloud.sh
   ```

5. **Crear Directorio de Backups**:
   ```bash
   # Crear el directorio de backups en Unraid
   sudo mkdir -p /mnt/unraid_nextcloud/backups
   sudo chown -R www-data:www-data /mnt/unraid_nextcloud/backups
   sudo chmod -R 750 /mnt/unraid_nextcloud/backups
   ```

#### Características de los Scripts
1. **Script de Backup**:
   - Crea una carpeta por día con formato YYYYMMDD
   - Realiza tres tipos de backup:
     - Base de datos MariaDB
     - Archivos de configuración (config, themes, apps, Apache, SSL)
     - Backup completo (excluyendo datos de Unraid)
   - Mantiene backups de los últimos 7 días
   - Registra todas las operaciones en el log
   - **IMPORTANTE**: Actualiza el registro de versiones en la base de datos

2. **Script de Restauración**:
   - Muestra los últimos 5 backups disponibles
   - Permite seleccionar qué backup restaurar
   - Opción de restaurar el más reciente por defecto
   - Requiere confirmación antes de restaurar
   - Restaura:
     - Base de datos
     - Archivos de configuración
     - Archivos de Nextcloud
   - Ajusta permisos automáticamente
   - **IMPORTANTE**: Verifica y actualiza las versiones de:
     - Nextcloud
     - MariaDB
     - PHP
     - Apache

#### Registro de Versiones
Después de cada backup o restauración, se actualiza el registro de versiones en la base de datos:
```sql
-- Tabla de registro de versiones
CREATE TABLE IF NOT EXISTS nextcloud_versions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    backup_date DATETIME,
    nextcloud_version VARCHAR(50),
    mariadb_version VARCHAR(50),
    php_version VARCHAR(50),
    apache_version VARCHAR(50),
    backup_type ENUM('manual', 'automatic'),
    backup_path VARCHAR(255)
);
```

#### Uso de los Scripts
1. **Backup Manual**:
```bash
sudo /usr/local/bin/backup-nextcloud.sh
```

2. **Restauración**:
```bash
sudo /usr/local/bin/restore-nextcloud.sh
```

#### Verificación de Versiones
Para verificar las versiones actuales:
```bash
# Versión de Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ status

# Versión de MariaDB
mysql --version

# Versión de PHP
php -v

# Versión de Apache
apache2 -v
```

### Montaje de Unraid
- Punto de montaje: /mnt/unraid_nextcloud
- IP del servidor Unraid: 192.168.2.75
- Compartido: Nextcloud
- **IMPORTANTE**: Los backups se almacenan en el servidor Unraid para mayor seguridad y redundancia
- Ruta de backups en Unraid: /mnt/unraid_nextcloud/backups/

## Solución de Problemas Comunes
### Permisos
```bash
# Corregir permisos
sudo chown -R www-data:www-data /var/www/html/nextcloud
sudo find /var/www/html/nextcloud/ -type d -exec chmod 750 {} \;
sudo find /var/www/html/nextcloud/ -type f -exec chmod 640 {} \;
```

### Verificar Estado
```bash
# Verificar estado de Nextcloud
sudo -u www-data php occ status

# Verificar estado de Apache
sudo systemctl status apache2
```

## Notas Importantes
- El servidor usa un certificado autofirmado, por lo que los navegadores mostrarán una advertencia de seguridad
- Los puertos no estándar (7086 y 444) requieren que se especifiquen en la URL
- URL de acceso: https://vpn.cobanetworks.com:444

## Contacto y Soporte
- Administrador: Rodrigo
- Documentación mantenida en GitHub: https://github.com/rojarrolla/nextcloud-docs

## Credenciales Importantes
### Base de Datos
- **Usuario DB**: nextcloud
- **Contraseña DB**: NextCloud2025!
- **Base de datos**: nextcloud

### Usuarios del Sistema
- **nextadmin** (administrador)
- **Rodrigo** (administrador, username: rod)
- **Ahernandez**
- **Manolo**

### Configuración de Nextcloud
- **Salt de contraseñas**: cld5z8LBbTgOLexg4Kc0drzYF4fW53
- **Ubicación de configuración**: /var/www/html/nextcloud/config/config.php

### Scripts de Backup
- **Usuario DB para backup**: nextcloud
- **Contraseña DB para backup**: NextCloud2025!
- **Ubicación de logs**: /var/log/nextcloud-backup.log

---
Última actualización: Mayo 2025 