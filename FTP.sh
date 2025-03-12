#!/bin/bash

# Configurar IP
configurar_ip() {
    ip_address=${1:-192.168.1.10}
    sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOT
network:
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            addresses: [$ip_address/24]
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
    version: 2
EOT
    sudo netplan apply
    echo "La IP ha sido configurada como $ip_address"
}

# Configurar FTP
configurar_ftp() {
    sudo apt install -y vsftpd
    sudo ufw enable
    sudo ufw allow 20/tcp
    sudo ufw allow 21/tcp
    sudo ufw allow 40000:50000/tcp
    sudo ufw reload

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
    sudo systemctl restart vsftpd
    echo "FTP configurado y reiniciado."
    sudo mkdir -p /srv/ftp/{publico,reprobados,recursadores}
    sudo chmod 777 /srv/ftp/{reprobados,recursadores}
}

# Crear usuario
crear_usuario() {
    read -p "Ingrese nombre de usuario: " nombre
    sudo adduser --disabled-password --gecos "" "$nombre"
    read -s -p "Ingrese contraseña: " contrasena
    echo "$nombre:$contrasena" | sudo chpasswd
    read -p "Seleccione grupo (1. Reprobados, 2. Recursadores): " opcion
    grupo=$([[ "$opcion" == "1" ]] && echo "reprobados" || echo "recursadores")
    sudo mkdir -p /srv/ftp/$nombre/$grupo
    sudo chown $nombre:ftp /srv/ftp/$nombre/$grupo
    sudo chmod 770 /srv/ftp/$nombre/$grupo
    sudo mount --bind /srv/ftp/$grupo /srv/ftp/$nombre/$grupo
    echo "Usuario $nombre creado en el grupo $grupo."
}

# Cambiar grupo
cambiar_grupo() {
    read -p "Ingrese usuario a cambiar de grupo: " nombre
    grupo_actual=$(ls /srv/ftp/$nombre | grep -E 'reprobados|recursadores')
    nuevo_grupo=$([[ "$grupo_actual" == "reprobados" ]] && echo "recursadores" || echo "reprobados")
    sudo umount /srv/ftp/$nombre/$grupo_actual
    sudo rm -r /srv/ftp/$nombre/$grupo_actual
    sudo mkdir -p /srv/ftp/$nombre/$nuevo_grupo
    sudo mount --bind /srv/ftp/$nuevo_grupo /srv/ftp/$nombre/$nuevo_grupo
    echo "Usuario $nombre ahora pertenece a $nuevo_grupo."
}

# Ejecutar configuraciones iniciales
configurar_ip
configurar_ftp

# Menú principal
while true; do
    echo -e "\n=== Menú FTP ==="
    echo "1. Crear usuario"
    echo "2. Cambiar grupo"
    echo "3. Salir"
    read -p "Seleccione una opción: " opcion
    case $opcion in
        1) crear_usuario ;;
        2) cambiar_grupo ;;
        3) exit 0 ;;
        *) echo "Opción no válida" ;;
    esac
done
