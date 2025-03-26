
ssl_choice=$1 
# Instalar el servicio FTP
sudo apt install vsftpd

# Habilitar el firewall y abrir los puertos necesarios
sudo ufw enable
sudo ufw allow 20/tcp
#sudo ufw allow 990/tcp
sudo ufw allow 40000:50000/tcp
#sudo ufw reload

echo "Firewall configurado y puertos abiertos."

if [[ "$ssl_choice" == "s" ]]; then
sudo ufw allow 990/tcp
sudo ufw reload
    echo "Habilitando SSL en vsftpd..."

    # Crear carpeta de certificados si no existe
    sudo mkdir -p /etc/ssl/custom/

    # Generar certificado SSL
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/custom/vsftpd.key \
        -out /etc/ssl/custom/vsftpd.crt \
        -subj "/C=MX/ST=Sinaloa/L=Mochis/O=pauserver/OU=IT/CN=192.168.1.10"

    echo "Certificado SSL generado correctamente."

    # Configuración de vsftpd con SSL
    sudo tee /etc/vsftpd.conf > /dev/null <<EOT
listen=YES
listen_ipv6=NO
listen_port=990
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
rsa_cert_file=/etc/ssl/custom/vsftpd.crt
rsa_private_key_file=/etc/ssl/custom/vsftpd.key
ssl_enable=YES
implicit_ssl=YES
force_local_logins_ssl=YES
force_local_data_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH
allow_anon_ssl=YES
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

    echo "Configuración de vsftpd con SSL aplicada."

else
    echo "Configuracion sin SSL aplicada."
    sudo ufw allow 21/tcp
    sudo ufw reload

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

    echo "Configuración de vsftpd sin SSL aplicada."
fi

# Reiniciar el servicio FTP
sudo systemctl restart vsftpd
sudo systemctl status vsftpd --no-pager

echo "Servicio FTP configurado y reiniciado."

# Crear carpetas principales
sudo mkdir -p /srv/ftp/publico
sudo mkdir -p /srv/ftp/reprobados
sudo mkdir -p /srv/ftp/recursadores
sudo mkdir -p /srv/ftp/publico/publico

# Asignar permisos
sudo chown nobody:nogroup /srv/ftp/publico/publico
sudo chmod 755 /srv/ftp/publico/publico
sudo chown nobody:nogroup /srv/ftp/publico
sudo chmod 755 /srv/ftp/publico
sudo chown nobody:nogroup /srv/ftp/reprobados
sudo chmod 777 /srv/ftp/reprobados
sudo chown nobody:nogroup /srv/ftp/recursadores
sudo chmod 777 /srv/ftp/recursadores

echo "Carpetas FTP creadas."