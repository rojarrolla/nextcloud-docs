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
- **Base de datos**: nextcloud
- **Ubicación backups**: /var/backups/nextcloud/

## Directorios Importantes
- **Instalación Nextcloud**: /var/www/html/nextcloud
- **Datos**: /mnt/unraid_nextcloud/data
- **Configuración**: /var/www/html/nextcloud/config
- **Logs Apache**: /var/log/apache2/

## Certificados SSL
- **Certificado**: /etc/ssl/certs/nextcloud-selfsigned.crt
- **Llave privada**: /etc/ssl/private/nextcloud-selfsigned.key
- Validez: 365 días
- **Certificado adicional**: Let's Encrypt, ubicado en /etc/letsencrypt/live/ (renovación automática)
- El certificado de Let's Encrypt se actualiza dos veces al día mediante tarea programada (cron)

## Configuración de Seguridad
- Forzado de HTTPS
- Certificado SSL autofirmado
- Firewall UFW activo
- Acceso restringido por IP a panel de administración

## Mantenimiento
### Backups
- Respaldos diarios completos que incluyen:
  - Base de datos MariaDB
  - Archivos de configuración de Nextcloud
  - Certificados SSL (autofirmado y Let's Encrypt)
  - Archivos de configuración de Apache
  - Datos de Nextcloud
- Ubicación: /var/backups/nextcloud/
- Los backups se ejecutan diariamente a las 2:00 AM
- Logs de backup: /var/log/nextcloud-backup.log
- **Renovación de certificado Let's Encrypt**: Se ejecuta automáticamente dos veces al día para mantener la validez del certificado SSL

### Scripts de Backup y Restauración
#### Ubicación de los Scripts
- Script de backup: `/usr/local/bin/backup-nextcloud.sh`
- Script de restauración: `/mnt/unraid_nextcloud/backups/restore-nextcloud.sh`
- Configuración de cron: `/etc/cron.d/nextcloud-backups`
- Archivo de configuración: `/etc/nextcloud/backup.conf`
- Credenciales MySQL: `/etc/nextcloud/mysql.cnf`

#### Configuración Segura
1. Crear el archivo de configuración:
```bash
sudo mkdir -p /etc/nextcloud
sudo cp /usr/local/bin/backup.conf.example /etc/nextcloud/backup.conf
```

2. Crear el archivo de credenciales MySQL:
```bash
sudo nano /etc/nextcloud/mysql.cnf
```
Añadir:
```ini
[client]
user=nextcloud
password=tu_contraseña
```

3. Asegurar los permisos:
```bash
sudo chown root:root /etc/nextcloud/mysql.cnf
sudo chmod 600 /etc/nextcloud/mysql.cnf
```

#### Uso del Script de Backup
El script de backup se ejecuta automáticamente cada día a las 2:00 AM. Si necesitas ejecutarlo manualmente:
```bash
sudo /usr/local/bin/backup-nextcloud.sh
```

#### Uso del Script de Restauración
Para restaurar un backup:
```bash
# Dar permisos de ejecución al script (solo la primera vez)
sudo chmod +x /mnt/unraid_nextcloud/backups/restore-nextcloud.sh

# Ejecutar la restauración (reemplaza YYYYMMDD con la fecha del backup)
sudo /mnt/unraid_nextcloud/backups/restore-nextcloud.sh YYYYMMDD
```

### Montaje de Unraid
- Punto de montaje: /mnt/unraid_nextcloud
- IP del servidor Unraid: 192.168.2.75
- Compartido: Nextcloud

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

---
Última actualización: Mayo 2025 