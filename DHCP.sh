#!/bin/bash

# Función para validar una dirección IP
validar_ip() {
    local ip_address=$1
    local valid_format="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

    if [[ $ip_address =~ $valid_format ]]; then
        return 0
    else
        return 1
    fi
}

# Solicitar la dirección IP del servidor DNS
while true; do
    read -p "Ingrese la dirección IP del servidor DNS: " dns_ip
    if validar_ip "$dns_ip"; then
        echo "¡Dirección IP válida ingresada: $dns_ip!"
        break
    else
        echo "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente."
    fi
done

# Solicitar la IP de inicio del rango DHCP
while true; do
    read -p "Ingrese la IP de inicio del rango DHCP: " inicio_ip
    if validar_ip "$inicio_ip"; then
        echo "IP de inicio válida: $inicio_ip"
        break
    else
        echo "La IP ingresada no es válida. Inténtelo de nuevo."
    fi
done

# Solicitar la IP de fin del rango DHCP
while true; do
    read -p "Ingrese la IP de fin del rango DHCP: " fin_ip
    if validar_ip "$fin_ip"; then
        fin_octeto=$(echo "$fin_ip" | awk -F. '{print $4}')
        inicio_octeto=$(echo "$inicio_ip" | awk -F. '{print $4}')

        if (( fin_octeto > inicio_octeto )); then
            echo "IP de fin válida: $fin_ip"
            break
        else
            echo "La IP final debe tener el último octeto mayor que la IP inicial."
        fi
    else
        echo "La IP ingresada no es válida. Inténtelo de nuevo."
    fi
done

# Mostrar la configuración completa
echo "Configuración completa:"
echo "Servidor DHCP: $dns_ip"
echo "Rango de IPs: $inicio_ip - $fin_ip"

# Extraer la subred y la puerta de enlace
IFS='.' read -r o1 o2 o3 o4 <<< "$dns_ip"
subnet="${o1}.${o2}.${o3}.0"
gateway="${o1}.${o2}.${o3}.1"

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


