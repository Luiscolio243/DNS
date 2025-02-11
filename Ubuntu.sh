#!/bin/bash

# Función para validar una dirección IP
Validar-IP() { 
    local ip_address=$1 
    local valid_format="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

    if [[ $ip_address =~ $valid_format ]]; then 
        return 0 
    else 
        return 1 
    fi 
} 

# Función para validar un dominio (que termine en .com y tenga una estructura válida)
Validar-Dominio() { 
    local domain=$1 
    local valid_format="^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"

    if [[ $domain =~ $valid_format ]] && [[ $domain == *.com ]]; then 
        return 0 
    else 
        return 1 
    fi 
}

# Solicitar la dirección IP del servidor DNS 
while true; do 
    read -p "Ingrese la dirección IP del servidor DNS: " ip_address 
    if Validar-IP "$ip_address"; then 
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

# Separar la IP en sus cuatro octetos y generar la versión inversa
IFS='.' read -r o1 o2 o3 o4 <<< "$ip_address"
reverse_ip="${o3}.${o2}.${o1}"
last_octet="$o4"

# Mostrar los valores generados
echo "Octetos: $o1, $o2, $o3, $o4"
echo "IP invertida: $reverse_ip"
echo "Último octeto: $last_octet"

