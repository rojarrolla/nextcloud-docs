# Manual de Comandos - Servidor Nextcloud

## 1. Gestión de Nextcloud

### Modo Mantenimiento
```bash
# Activar modo mantenimiento
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode --on

# Desactivar modo mantenimiento
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode --off

# Verificar estado del modo mantenimiento
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:mode
```

### Gestión de Usuarios
```bash
# Listar todos los usuarios
sudo -u www-data php /var/www/html/nextcloud/occ user:list

# Crear nuevo usuario
sudo -u www-data php /var/www/html/nextcloud/occ user:add [username] --password-from-env

# Eliminar usuario
sudo -u www-data php /var/www/html/nextcloud/occ user:delete [username]

# Cambiar contraseña de usuario
sudo -u www-data php /var/www/html/nextcloud/occ user:resetpassword [username]

# Añadir usuario a grupo
sudo -u www-data php /var/www/html/nextcloud/occ group:adduser [groupname] [username]

# Listar grupos
sudo -u www-data php /var/www/html/nextcloud/occ group:list
```

### Verificación y Reparación
```bash
# Verificar estado de Nextcloud
sudo -u www-data php /var/www/html/nextcloud/occ status

# Verificar integridad del sistema
sudo -u www-data php /var/www/html/nextcloud/occ integrity:check-core

# Reparar base de datos
sudo -u www-data php /var/www/html/nextcloud/occ maintenance:repair
```

## 2. Gestión de MariaDB

### Conexión y Consultas
```bash
# Conectar a MariaDB
mysql -u nextcloud -p

# Listar bases de datos
SHOW DATABASES;

# Usar base de datos Nextcloud
USE nextcloud;

# Listar tablas
SHOW TABLES;

# Consultar usuarios
SELECT * FROM oc_users;

# Consultar grupos
SELECT * FROM oc_groups;
```

### Backups de Base de Datos
```bash
# Backup manual
mysqldump -u nextcloud -p nextcloud > /var/backups/nextcloud/nextcloud_$(date +%Y%m%d).sql

# Restaurar backup
mysql -u nextcloud -p nextcloud < /var/backups/nextcloud/nextcloud_YYYYMMDD.sql
```

## 3. Gestión de Certificados SSL

### Let's Encrypt
```bash
# Verificar estado de certificados
sudo certbot certificates

# Renovar certificados manualmente
sudo certbot renew

# Forzar renovación
sudo certbot renew --force-renewal
```

### Certificados Autofirmados
```bash
# Generar nuevo certificado autofirmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/nextcloud-selfsigned.key \
-out /etc/ssl/certs/nextcloud-selfsigned.crt
```

## 4. Gestión de Apache

### Control del Servicio
```bash
# Verificar estado
sudo systemctl status apache2

# Reiniciar Apache
sudo systemctl restart apache2

# Ver logs en tiempo real
sudo tail -f /var/log/apache2/error.log
```

### Configuración
```bash
# Verificar sintaxis de configuración
sudo apache2ctl configtest

# Recargar configuración
sudo systemctl reload apache2
```

## 5. Montaje de Unraid

### Montaje Manual
```bash
# Crear punto de montaje
sudo mkdir -p /mnt/unraid_nextcloud

# Montar compartido
sudo mount -t nfs 192.168.2.75:/Nextcloud /mnt/unraid_nextcloud

# Verificar montaje
df -h /mnt/unraid_nextcloud
```

### Montaje Automático (fstab)
```bash
# Añadir a /etc/fstab
192.168.2.75:/Nextcloud /mnt/unraid_nextcloud nfs defaults 0 0
```

## 6. Gestión de Permisos

### Corrección de Permisos
```bash
# Corregir permisos de Nextcloud
sudo chown -R www-data:www-data /var/www/html/nextcloud
sudo find /var/www/html/nextcloud/ -type d -exec chmod 750 {} \;
sudo find /var/www/html/nextcloud/ -type f -exec chmod 640 {} \;

# Corregir permisos de datos
sudo chown -R www-data:www-data /mnt/unraid_nextcloud/data
```

## 7. Monitoreo y Logs

### Verificación de Espacio
```bash
# Ver espacio en disco
df -h

# Ver espacio usado por directorios
du -sh /var/www/html/nextcloud/
du -sh /mnt/unraid_nextcloud/data/
```

### Logs
```bash
# Ver logs de Nextcloud
sudo tail -f /var/www/html/nextcloud/data/nextcloud.log

# Ver logs de Apache
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log
```

## 8. Firewall (UFW)

### Gestión de Reglas
```bash
# Ver estado
sudo ufw status

# Permitir puertos
sudo ufw allow 7086/tcp
sudo ufw allow 444/tcp
sudo ufw allow 3306/tcp

# Bloquear IP
sudo ufw deny from [IP_ADDRESS] to any
```

## 9. Backups

### Backup Manual
```bash
# Ejecutar backup manual
sudo /usr/local/bin/backup-nextcloud.sh

# Restaurar backup
sudo /mnt/unraid_nextcloud/backups/restore-nextcloud.sh YYYYMMDD
```

### Verificación de Backups
```bash
# Listar backups disponibles
ls -lh /var/backups/nextcloud/

# Verificar logs de backup
cat /var/log/nextcloud-backup.log
```

## Notas Importantes
- Siempre verifique el estado del sistema antes de realizar operaciones críticas
- Mantenga copias de seguridad antes de realizar cambios importantes
- Documente cualquier cambio en la configuración
- Revise los logs regularmente para detectar problemas potenciales

---
Última actualización: Mayo 2024 