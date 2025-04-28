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
- **Datos**: /var/www/html/nextcloud/data
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
- Respaldos diarios de la base de datos
- Respaldos semanales de archivos de configuración
- Ubicación: /var/backups/nextcloud/
- **Renovación de certificado Let's Encrypt**: Se ejecuta automáticamente dos veces al día para mantener la validez del certificado SSL

### Actualizaciones
```bash
# Actualizar Nextcloud
sudo -u www-data php occ upgrade

# Verificar estado
sudo -u www-data php occ status
```

### Tareas Programadas (Cron)
- Cron de sistema configurado para tareas de mantenimiento
- Ejecutado como usuario www-data

## Configuración de Red
### USG (Ubiquiti Security Gateway)
- Port forwarding configurado para puertos 7086 y 444
- Reglas de firewall para permitir tráfico necesario
- Gateway: 192.168.2.1

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
Última actualización: Marzo 2024 