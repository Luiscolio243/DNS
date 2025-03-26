sudo apt install vsftpd

# Habilitar el firewall y abrir los puertos necesarios
sudo ufw enable
sudo ufw allow 20/tcp
sudo ufw allow 21/tcp
sudo ufw allow 40000:50000/tcp
sudo ufw reload

#Editar archivo
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
pasv_address=192.168.1.2
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/srv/ftp/$USER
EOT

sudo systemctl restart vsftpd
sudo systemctl status vsftpd --no-pager

#Usuario para windows
sudo adduser windows #luego te pedira una contrasena, yo le puse 1234 en los dos usarios

sudo mkdir -p "/srv/ftp/windows"
sudo chown "windows:ftp" "/srv/ftp/windows"
sudo chmod 770 "/srv/ftp/windows"

sudo mkdir -p "/srv/ftp/windows/Apache"
sudo chown "windows:ftp" "/srv/ftp/windows/Apache"
sudo chmod 770 "/srv/ftp/windows/Apache"

sudo mkdir -p "/srv/ftp/windows/Nginx"
sudo chown "windows:ftp" "/srv/ftp/windows/Nginx"
sudo chmod 770 "/srv/ftp/windows/Nginx"


#Usuario para ubuntu 
sudo adduser ubuntu

sudo mkdir -p "/srv/ftp/ubuntu"
sudo chown "ubuntu:ftp" "/srv/ftp/ubuntu"
sudo chmod 770 "/srv/ftp/ubuntu"

sudo mkdir -p "/srv/ftp/ubuntu/Apache"
sudo chown "ubuntu:ftp" "/srv/ftp/ubuntu/Apache"
sudo chmod 770 "/srv/ftp/ubuntu/Apache"

sudo mkdir -p "/srv/ftp/ubuntu/Nginx"
sudo chown "ubuntu:ftp" "/srv/ftp/ubuntu/Nginx"
sudo chmod 770 "/srv/ftp/ubuntu/Nginx"

sudo mkdir -p "/srv/ftp/ubuntu/OpenLiteSpeed"
sudo chown "ubuntu:ftp" "/srv/ftp/ubuntu/OpenLiteSpeed"
sudo chmod 770 "/srv/ftp/ubuntu/OpenLiteSpeed"


#Descarga los zip en su respectiva carpeta
sudo wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
-P /srv/ftp/windows/Apache/ \
"https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip"

#Apache para Ubuntu
sudo wget -P /srv/ftp/ubuntu/Apache/ https://downloads.apache.org/httpd/httpd-2.4.63.tar.gz

#Nginx para Ubuntu
sudo wget -P /srv/ftp/ubuntu/Nginx/ https://nginx.org/download/nginx-1.27.4.tar.gz
sudo wget -P /srv/ftp/ubuntu/Nginx/ https://nginx.org/download/nginx-1.26.3.tar.gz
    
#OpenLiteSpeed para Ubuntu
sudo wget -P /srv/ftp/ubuntu/OpenLiteSpeed/ https://openlitespeed.org/packages/openlitespeed-1.7.19.tgz
sudo wget -P /srv/ftp/ubuntu/OpenLiteSpeed/ https://openlitespeed.org/packages/openlitespeed-1.8.3.tgz

#Nginx para Windows
sudo wget -P /srv/ftp/windows/Nginx https://nginx.org/download/nginx-1.27.4.zip
sudo wget -P /srv/ftp/windows/Nginx https://nginx.org/download/nginx-1.26.3.zip



sudo wget -P /srv/ftp/windows/Apache/ https://www.apachelounge.com/download/VS17/binaries/httpd-2.4.63-250207-win64-VS17.zip