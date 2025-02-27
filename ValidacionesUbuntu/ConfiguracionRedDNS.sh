#!/bin/bash

# Función para configurar la red en Netplan
ConfigurarNetplan() {
    local ip_address=$1
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

    # Aplicar la configuración de red
    sudo netplan apply
}