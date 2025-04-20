# Nextcloud Server Configuration Documentation

## Información General
- **Dominio**: vpn.cobanetworks.com
- **Puertos**: 
  - HTTP: 7086
  - HTTPS: 444
- **Versión de Software**:
  - Apache: 2.4.58
  - PHP: 8.2.28
  - MariaDB: 10.11.11
  - Sistema Operativo: Ubuntu

## Estructura de Almacenamiento
### Servidor Principal
- **Ubicación**: Servidor local
- **Ruta de instalación**: `/var/www/html/nextcloud`
- **Usuario del sistema**: www-data

### Almacenamiento Externo (Unraid)
- **Servidor**: 192.168.2.75
- **Share**: //192.168.2.75/Nextcloud
- **Punto de montaje**: /mnt/unraid_nextcloud
- **Espacio total**: 9.1TB
- **Configuración de montaje**:
  ```
  //192.168.2.75/Nextcloud /mnt/unraid_nextcloud cifs rw,relatime,vers=3.0,cache=strict,
  username=nextcloud,uid=33,forceuid,gid=33,forcegid,file_mode=0770,dir_mode=0770,
  iocharset=utf8,soft,serverino,mapposix,rsize=4194304,wsize=4194304
  ```

## Base de Datos
- **Tipo**: MariaDB
- **Host**: localhost
- **Nombre de BD**: nextcloud
- **Usuario**: nextcloud

## Usuarios y Grupos
### Grupos
1. **Users** (usuarios regulares)
   - Ahernandez (5GB)
   - Ben (10GB)
   - Manolo (10GB)
   - vc (10GB)

2. **admin**
   - Rodrigo (sin límite)
   - nextadmin (sin límite)

## Procedimiento de Respaldo

### 1. Respaldo de Datos
```bash
# Detener Apache
sudo systemctl stop apache2

# Respaldar directorio de datos
sudo rsync -avz /mnt/unraid_nextcloud/data/ /ruta/backup/data/

# Respaldar configuración de Nextcloud
sudo rsync -avz /var/www/html/nextcloud/config/ /ruta/backup/config/

# Respaldo de la base de datos
sudo mysqldump --single-transaction -u nextcloud -p nextcloud > nextcloud-sqlbkp.bak

# Respaldar certificados SSL
sudo cp /etc/ssl/private/nextcloud-selfsigned.key /ruta/backup/ssl/
sudo cp /etc/ssl/certs/nextcloud-selfsigned.crt /ruta/backup/ssl/

# Reiniciar Apache
sudo systemctl start apache2
```

### 2. Respaldo de Configuración Apache
```bash
# Respaldar configuración de Apache
sudo cp /etc/apache2/sites-available/nextcloud*.conf /ruta/backup/apache/
```

## Procedimiento de Restauración

### 1. Instalación Base
```bash
# Instalar dependencias
sudo apt update
sudo apt install apache2 mariadb-server php8.2 php8.2-gd php8.2-mysql php8.2-curl \
php8.2-mbstring php8.2-intl php8.2-gmp php8.2-bcmath php8.2-xml php8.2-zip

# Configurar Apache
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo a2enmod ssl
```

### 2. Configuración de Base de Datos
```bash
# Crear base de datos y usuario
mysql -u root -p
CREATE DATABASE nextcloud;
CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'tu_contraseña';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Montaje del Almacenamiento
```bash
# Crear punto de montaje
sudo mkdir -p /mnt/unraid_nextcloud

# Agregar al fstab
sudo echo "//192.168.2.75/Nextcloud /mnt/unraid_nextcloud cifs rw,relatime,vers=3.0,cache=strict,username=nextcloud,uid=33,forceuid,gid=33,forcegid,file_mode=0770,dir_mode=0770,iocharset=utf8,soft,serverino,mapposix,rsize=4194304,wsize=4194304,credentials=/root/.smbcredentials,_netdev 0 0" >> /etc/fstab

# Crear archivo de credenciales
sudo echo "username=nextcloud
password=tu_contraseña" > /root/.smbcredentials
sudo chmod 600 /root/.smbcredentials

# Montar
sudo mount -a
```

### 4. Configuración SSL
```bash
# Generar certificado SSL autofirmado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/nextcloud-selfsigned.key \
-out /etc/ssl/certs/nextcloud-selfsigned.crt \
-subj "/C=MX/ST=State/L=City/O=Organization/CN=vpn.cobanetworks.com"

# Configurar permisos
sudo chmod 600 /etc/ssl/private/nextcloud-selfsigned.key
sudo chmod 644 /etc/ssl/certs/nextcloud-selfsigned.crt

# Crear configuración SSL de Apache
sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud-ssl.conf << EOL
<VirtualHost *:444>
    ServerName vpn.cobanetworks.com
    DocumentRoot /var/www/html/nextcloud
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/nextcloud-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/nextcloud-selfsigned.key
    
    <Directory /var/www/html/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOL'

# Crear configuración HTTP (para redirección)
sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud.conf << EOL
<VirtualHost *:7086>
    ServerName vpn.cobanetworks.com
    DocumentRoot /var/www/html/nextcloud
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}:444%{REQUEST_URI} [L,R=301]
    
    <Directory /var/www/html/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
EOL'
```

### 5. Restauración de Datos
```bash
# Restaurar archivos de Nextcloud
sudo rsync -avz /ruta/backup/data/ /mnt/unraid_nextcloud/data/
sudo rsync -avz /ruta/backup/config/ /var/www/html/nextcloud/config/

# Restaurar certificados SSL (si se tienen respaldos)
sudo cp /ruta/backup/ssl/nextcloud-selfsigned.key /etc/ssl/private/
sudo cp /ruta/backup/ssl/nextcloud-selfsigned.crt /etc/ssl/certs/
sudo chmod 600 /etc/ssl/private/nextcloud-selfsigned.key
sudo chmod 644 /etc/ssl/certs/nextcloud-selfsigned.crt

# Restaurar base de datos
mysql -u nextcloud -p nextcloud < nextcloud-sqlbkp.bak

# Restaurar permisos
sudo chown -R www-data:www-data /var/www/html/nextcloud/
sudo chown -R www-data:www-data /mnt/unraid_nextcloud/data/
```

### 6. Configuración de Apache
```bash
# Configurar puertos personalizados
sudo sed -i 's/Listen 80/Listen 7086/' /etc/apache2/ports.conf
sudo sed -i 's/Listen 443/Listen 444/' /etc/apache2/ports.conf

# Habilitar sitios y módulos necesarios
sudo a2ensite nextcloud.conf
sudo a2ensite nextcloud-ssl.conf
sudo a2enmod ssl
sudo a2enmod rewrite
sudo systemctl restart apache2
```

## Notas Importantes
1. Mantener respaldos regulares de la base de datos y certificados SSL
2. Verificar permisos después de restauraciones
3. Comprobar conexión con Unraid antes de restaurar
4. Actualizar las contraseñas en los archivos de configuración
5. El certificado SSL es autofirmado y generará advertencias en los navegadores
6. Para un certificado válido, considerar usar Let's Encrypt en el futuro

## Verificación Post-Restauración
```bash
# Verificar estado de Nextcloud
sudo -u www-data php occ status
sudo -u www-data php occ maintenance:mode --off

# Verificar permisos
sudo -u www-data php occ files:scan --all

# Verificar configuración SSL
sudo apache2ctl -t
curl -k https://vpn.cobanetworks.com:444
```

## Contactos de Soporte
- Administrador: Rodrigo (rrllamas@gmail.com)
- Backup Admin: nextadmin 

## Configuración de la Máquina Virtual
- **Sistema Operativo**: Ubuntu Server
- **Recursos asignados**:
  - CPU: Intel(R) Xeon(R) CPU E5-2470 v2 @ 2.40GHz
    - Núcleos: 10
    - Threads por núcleo: 1
  - RAM: 
    - Total: 11GB
    - Swap: 4GB
  - Disco del sistema: 
    - Total: 48GB (LVM)
    - Usado: 18GB
    - Disponible: 28GB
- **Red**: 
  - Interfaz: ens192 (VMware)
  - MAC: 00:0c:29:41:a3:d4
  - IP: 192.168.2.8
  - Máscara: /24 (255.255.255.0)
  - Gateway: 192.168.2.1
  - DNS: 127.0.0.53 (systemd-resolved)

## Configuración de Acceso Externo (USG)
### Port Forwarding en USG
- **Reglas de Port Forward**:
  - Puerto externo 7086 -> 192.168.2.8:7086 (HTTP)
  - Puerto externo 444 -> 192.168.2.8:444 (HTTPS)
  - Puerto externo 80 -> 192.168.2.8:80 (Solo para renovación de certificados SSL)

### Configuración en UniFi Controller
1. Acceder al UniFi Controller
2. Ir a Settings -> Routing & Firewall
3. Seleccionar la pestaña "Port Forwarding"
4. Agregar las reglas:
   ```
   Regla 1 (HTTP):
   - Name: Nextcloud HTTP
   - Forward IP: 192.168.2.8
   - Forward Port: 7086
   - Source Port: 7086
   - Protocol: TCP

   Regla 2 (HTTPS):
   - Name: Nextcloud HTTPS
   - Forward IP: 192.168.2.8
   - Forward Port: 444
   - Source Port: 444
   - Protocol: TCP

   Regla 3 (Let's Encrypt):
   - Name: Let's Encrypt Verification
   - Forward IP: 192.168.2.8
   - Forward Port: 80
   - Source Port: 80
   - Protocol: TCP
   ```

### Firewall Rules en USG
1. **Regla para Let's Encrypt**:
   ```
   - Name: Allow Let's Encrypt
   - Action: Accept
   - Protocol: TCP
   - Source Type: IP Address
   - Source Address: [IPs de Let's Encrypt]
   - Destination Type: IP Address
   - Destination Address: 192.168.2.8
   - Destination Port: 80
   ```
   Esta regla permite el acceso al puerto 80 solo desde los servidores de Let's Encrypt para la verificación y renovación de certificados.

2. **Regla de Bloqueo General Puerto 80**:
   ```
   - Name: Block Port 80
   - Action: Drop
   - Protocol: TCP
   - Source Type: Any
   - Destination Type: IP Address
   - Destination Address: 192.168.2.8
   - Destination Port: 80
   ```
   Esta regla bloquea todo el tráfico al puerto 80 excepto el que viene de Let's Encrypt.

### DNS y Dominio
- **Dominio**: vpn.cobanetworks.com
- **Configuración DNS**:
  - Tipo: A Record
  - Host: vpn
  - Apunta a: [IP PÚBLICA DEL USG]
  - TTL: 300

### Consideraciones de Seguridad
1. Asegurarse de que el firewall del USG esté correctamente configurado
2. Mantener el UniFi Controller actualizado
3. Monitorear los logs del USG para detectar intentos de acceso no autorizados
4. Considerar la implementación de VPN para acceso remoto más seguro

## Dependencias Adicionales Instaladas
```bash
# Paquetes adicionales necesarios
sudo apt install \
    php8.2-imagick \
    php8.2-bz2 \
    php8.2-redis \
    php8.2-ldap \
    php8.2-smbclient \
    php8.2-ftp \
    php8.2-imap \
    php8.2-gmp \
    cifs-utils \
    unzip \
    redis-server
```

## Optimizaciones del Sistema
### PHP
```bash
# Editar php.ini
sudo nano /etc/php/8.2/apache2/php.ini

# Configuraciones recomendadas
memory_limit = 512M
upload_max_filesize = 16G
post_max_size = 16G
max_execution_time = 3600
max_input_time = 3600
date.timezone = America/Mexico_City
opcache.enable=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=1
opcache.save_comments=1
```

### Apache
```bash
# Editar configuración de Apache
sudo nano /etc/apache2/apache2.conf

# Agregar o modificar
<Directory /var/www/html/nextcloud>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
</Directory>

# Configurar módulos adicionales
sudo a2enmod headers
sudo a2enmod env
sudo a2enmod dir
sudo a2enmod mime
sudo a2enmod setenvif
```

### Redis
```bash
# Instalar y configurar Redis
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Configurar Nextcloud para usar Redis
sudo -u www-data php occ config:system:set redis host --value="localhost"
sudo -u www-data php occ config:system:set redis port --value="6379"
sudo -u www-data php occ config:system:set memcache.local --value="\OC\Memcache\Redis"
sudo -u www-data php occ config:system:set memcache.locking --value="\OC\Memcache\Redis"
```

### Tareas Programadas
```bash
# Configurar cron para Nextcloud
echo "*/5 * * * * www-data php -f /var/www/html/nextcloud/cron.php" | sudo tee /etc/cron.d/nextcloud

# Habilitar cron en Nextcloud
sudo -u www-data php occ background:cron
```

## Seguridad

### Firewall (UFW)
```bash
# Configurar firewall
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 7086/tcp
sudo ufw allow 444/tcp
sudo ufw allow ssh
sudo ufw enable
```

### Fail2ban
```bash
# Instalar y configurar fail2ban
sudo apt install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Configurar protección para Nextcloud
sudo bash -c 'cat > /etc/fail2ban/jail.d/nextcloud.local << EOL
[nextcloud]
enabled = true
port = 7086,444
protocol = tcp
filter = nextcloud
logpath = /var/www/html/nextcloud/data/nextcloud.log
maxretry = 3
bantime = 86400
findtime = 43200
EOL'

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Mantenimiento Regular

### Tareas Diarias
```bash
# Verificar logs
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/www/html/nextcloud/data/nextcloud.log

# Verificar estado
sudo -u www-data php occ status
sudo -u www-data php occ maintenance:mode --off
```

### Tareas Semanales
```bash
# Respaldo de la base de datos
sudo mysqldump --single-transaction -u nextcloud -p nextcloud > /ruta/backup/nextcloud-$(date +%Y%m%d).sql

# Escanear archivos
sudo -u www-data php occ files:scan --all

# Verificar actualizaciones
sudo -u www-data php occ update:check
```

### Tareas Mensuales
```bash
# Limpiar caché y archivos temporales
sudo -u www-data php occ maintenance:repair
sudo -u www-data php occ maintenance:mimetype:update-js
sudo -u www-data php occ files:cleanup

# Renovar certificado SSL (si es necesario)
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/nextcloud-selfsigned.key \
-out /etc/ssl/certs/nextcloud-selfsigned.crt \
-subj "/C=MX/ST=State/L=City/O=Organization/CN=vpn.cobanetworks.com"
```

## Procedimiento de Recuperación ante Desastres

### 1. Respaldo Completo del Sistema
```bash
# Crear snapshot de la VM (si es posible)
# Respaldar configuración completa
sudo tar -czf /ruta/backup/nextcloud-full-$(date +%Y%m%d).tar.gz \
    /var/www/html/nextcloud \
    /etc/apache2 \
    /etc/php \
    /etc/mysql \
    /etc/ssl \
    /root/.smbcredentials
```

### 2. Restauración Completa
1. Instalar Ubuntu Server limpio
2. Seguir el procedimiento de instalación base
3. Restaurar respaldos
4. Verificar permisos y configuraciones
5. Probar funcionalidad

## Monitoreo
- Logs de Apache: `/var/log/apache2/`
- Logs de Nextcloud: `/var/www/html/nextcloud/data/nextcloud.log`
- Logs de Sistema: `journalctl -u apache2`
- Monitoreo de recursos: `htop`, `df -h`, `free -m` 