#!/bin/bash

# Función para configurar el servidor DHCP
ConfigurarDHCP() {
    local dns_ip=$1
    local inicio_ip=$2
    local fin_ip=$3

    # Extraer la subred y la puerta de enlace
    IFS='.' read -r o1 o2 o3 o4 <<< "$dns_ip"
    subnet="${o1}.${o2}.${o3}.0"
    gateway="${o1}.${o2}.${o3}.1"

    # Mostrar la configuración completa
    echo "Configuración completa:"
    echo "Servidor DHCP: $dns_ip"
    echo "Rango de IPs: $inicio_ip - $fin_ip"

    # Instalar el servicio DHCP
    echo "Instalando el servicio DHCP..."
    sudo apt-get install -y isc-dhcp-server

    # Configurar el archivo de red
    echo "Configurando el archivo de red..."
    sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOT
network:
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            addresses: [$dns_ip/24]
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
    version: 2
EOT

    # Aplicar la configuración de red
    sudo netplan apply

    # Configurar el archivo de configuración del servidor DHCP
    echo "Configurando el servidor DHCP..."
    sudo tee /etc/default/isc-dhcp-server > /dev/null <<EOT
INTERFACESv4="enp0s8"
INTERFACESv6=""
EOT

    # Configurar el archivo dhcpd.conf
    sudo tee /etc/dhcp/dhcpd.conf > /dev/null <<EOT
default-lease-time 3600;
max-lease-time 86400;

subnet $subnet netmask 255.255.255.0 {
  range $inicio_ip $fin_ip;
  option routers $gateway;
  option domain-name-servers 8.8.8.8;
}
EOT

    # Reiniciar el servicio DHCP
    echo "Reiniciando el servicio DHCP..."
    sudo service isc-dhcp-server restart
    sudo service isc-dhcp-server status

    echo "Configuración del servidor DHCP completada."
}