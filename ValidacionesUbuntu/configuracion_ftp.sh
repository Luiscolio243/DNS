 
# Instalar el servicio FTP
sudo apt install vsftpd

# Habilitar el firewall y abrir los puertos necesarios
sudo ufw enable
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 40000:50000/tcp
sudo ufw reload

echo "Firewall configurado y puertos abiertos."

# Configuración de vsftpd
sudo tee /etc/vsftpd.conf > /dev/null <<EOT
listen=YES
listen_ipv6=NO
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=NO
anon_mkdir_write_enable=NO
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
anon_root=/srv/ftp/publico
anon_other_write_enable=NO
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
pasv_address=192.168.1.10
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/srv/ftp/$USER
EOT

# Reiniciar el servicio FTP
sudo systemctl restart vsftpd
sudo systemctl status vsftpd --no-pager

echo "Servicio FTP configurado y reiniciado."

# Crear carpetas principales
sudo mkdir -p /srv/ftp/publico
sudo mkdir -p /srv/ftp/reprobados
sudo mkdir -p /srv/ftp/recursadores

# Asignar permisos
sudo chown nobody:nogroup /srv/ftp/publico
sudo chmod 755 /srv/ftp/publico
sudo chown nobody:nogroup /srv/ftp/reprobados
sudo chmod 777 /srv/ftp/reprobados
sudo chown nobody:nogroup /srv/ftp/recursadores
sudo chmod 777 /srv/ftp/recursadores

echo "Carpetas FTP creadas."