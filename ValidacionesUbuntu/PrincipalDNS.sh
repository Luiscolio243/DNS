#!/bin/bash

# Importar funciones de los otros archivos
source validaciones.sh
source configuracion_red.sh
source configuracion_bind.sh

# Solicitar la dirección IP del servidor DNS
while true; do
    read -p "Ingrese la dirección IP del servidor DNS: " ip_address
    if ValidarIP "$ip_address"; then
        echo "¡Dirección IP válida ingresada: $ip_address!"
        break
    else
        echo "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente."
    fi
done

# Solicitar el dominio
while true; do
    read -p "Ingrese el dominio: " domain
    if Validar-Dominio "$domain"; then
        echo "¡Dominio válido ingresado: $domain!"
        break
    else
        echo "El dominio ingresado no es válido o no termina con '.com'. Por favor, inténtelo nuevamente."
    fi
done

# Dividir la IP en segmentos y construir la IP inversa
IFS='.' read -r o1 o2 o3 o4 <<< "$ip_address"
reverse_ip="${o3}.${o2}.${o1}"
last_octet="$o4"

# Configurar la red en Netplan
ConfigurarNetplan "$ip_address"

# Instalar BIND9
InstalarBIND9

# Configurar named.conf.options
ConfigurarNamedOptions

# Configurar named.conf.local
ConfigurarNamedLocal "$domain" "$reverse_ip"

# Configurar el archivo de zona inversa
ConfigurarZonaInversa "$reverse_ip" "$domain" "$last_octet"

# Configurar el archivo de zona directa
ConfigurarZonaDirecta "$domain" "$ip_address"

# Configurar resolv.conf
ConfigurarResolvConf "$domain" "$ip_address"

# Reiniciar BIND9
ReiniciarBIND9

# Verificar la configuración DNS
VerificarDNS "$domain" "$ip_address"