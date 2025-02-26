#!/bin/bash

# Importar funciones de los otros archivos
source Validaciones.sh
source Solicitudes.sh
source ConfiguracionDHCP.sh

# Solicitar la dirección IP del servidor DNS
dns_ip=$(SolicitarIP "Ingrese la dirección IP del servidor DNS: ")

# Solicitar la IP de inicio del rango DHCP
inicio_ip=$(SolicitarIP "Ingrese la IP de inicio del rango DHCP: ")

# Solicitar la IP de fin del rango DHCP
fin_ip=$(SolicitarRangoIP "$inicio_ip")

# Configurar el servidor DHCP
ConfigurarDHCP "$dns_ip" "$inicio_ip" "$fin_ip"