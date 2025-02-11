#!/bin/bash

# Función para verificar si una IP es válida
verificar_ip() {
    local ip=$1
    local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    [[ $ip =~ $regex ]]
}

# Función para validar un dominio (solo .com)
verificar_dominio() {
    local dom=$1
    local regex="^[a-zA-Z0-9.-]+\.com$"

    [[ $dom =~ $regex ]]
}

# Pedir IP al usuario
while true; do
    read -p "Ingrese la dirección IP del servidor: " servidor_ip
    if verificar_ip "$servidor_ip"; then
        echo "IP válida: $servidor_ip"
        break
    else
        echo "Error: IP inválida. Intente nuevamente."
    fi
done

# Pedir dominio al usuario
while true; do
    read -p "Ingrese el dominio (debe terminar en .com): " dominio
    if verificar_dominio "$dominio"; then
        echo "Dominio válido: $dominio"
        break
    else
        echo "Error: Dominio inválido. Intente nuevamente."
    fi
done

# Extraer segmentos de la IP para la configuración inversa
IFS='.' read -r seg1 seg2 seg3 seg4 <<< "$servidor_ip"
ip_invertida="${seg3}.${seg2}.${seg1}"
ultimo_octeto="$seg4"

# Configurar red con Netplan
sudo bash -c "cat > /etc/netplan/01-config.yaml" <<EOT
network:
    renderer: networkd
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            addresses: [$servidor_ip/24]
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
    version: 2
EOT

# Aplicar configuración de red
sudo netplan apply

# Instalar BIND9
sudo apt update && sudo apt install -y bind9 bind9utils bind9-doc

# Configurar BIND9 (archivo de opciones)
sudo bash -c "cat > /etc/bind/named.conf.options" <<EOT
options {
    directory "/var/cache/bind";
    forwarders {
        8.8.8.8;
        1.1.1.1;
    };
    dnssec-validation auto;
    listen-on-v6 { any; };
    listen-on { any; };
};
EOT

# Configurar BIND9 (archivo de zonas)
sudo bash -c "cat > /etc/bind/named.conf.local" <<EOT
zone "$dominio" {
    type master;
    file "/etc/bind/db.$dominio";
};

zone "$ip_invertida.in-addr.arpa" {
    type master;
    file "/etc/bind/db.$ip_invertida";
};
EOT

# Crear archivo de zona inversa
sudo cp /etc/bind/db.127 /etc/bind/db.${ip_invertida}

sudo bash -c "cat > /etc/bind/db.${ip_invertida}" <<EOT
\$TTL 604800
@   IN  SOA $dominio. root.$dominio. (
        1       ; Serial
        604800  ; Refresh
        86400   ; Retry
        2419200 ; Expire
        604800 ) ; Negative Cache TTL
;
@   IN  NS  $dominio.
$ultimo_octeto  IN  PTR  $dominio.
EOT

# Crear archivo de zona directa
sudo cp /etc/bind/db.local /etc/bind/db.$dominio

sudo bash -c "cat > /etc/bind/db.$dominio" <<EOT
\$TTL 604800
@   IN  SOA $dominio. root.$dominio. (
        2       ; Serial
        604800  ; Refresh
        86400   ; Retry
        2419200 ; Expire
        604800 ) ; Negative Cache TTL
;
@   IN  NS  $dominio.
@   IN  A   $servidor_ip
www IN  CNAME $dominio.
EOT

# Asignar permisos correctos
sudo chmod 644 /etc/bind/db.${ip_invertida}
sudo chmod 644 /etc/bind/db.$dominio

# Configurar resolv.conf
sudo bash -c "cat > /etc/resolv.conf" <<EOT
search $dominio
nameserver $servidor_ip
options timeout:2 attempts:2 edns0 trust-ad
EOT

# Reiniciar servicio de BIND9
sudo systemctl restart bind9
sudo systemctl enable bind9
sudo systemctl status bind9 --no-pager

# Verificar servicio de DNS
echo "Verificando configuración..."
nslookup $dominio
nslookup www.$dominio
nslookup $servidor_ip
