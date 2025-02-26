#!/bin/bash

# Importar funciones de validación
source Validaciones.sh

# Función para solicitar una dirección IP válida
SolicitarIP() { 
    local mensaje=$1
    while true; do
        read -p "$mensaje" ip
        if ValidarIP "$ip"; then
            echo "¡Dirección IP válida ingresada: $ip!"
            echo "$ip"
            break
        else
            echo "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente."
        fi
    done
} 


# Función para solicitar un rango de IP válido
SolicitarRangoIP() {
    local inicio_ip=$1
    while true; do
        fin_ip=$(SolicitarIP "Ingrese la IP de fin del rango DHCP: ")
        fin_octeto=$(echo "$fin_ip" | awk -F. '{print $4}')
        inicio_octeto=$(echo "$inicio_ip" | awk -F. '{print $4}')

        if (( fin_octeto > inicio_octeto )); then
            echo "IP de fin válida: $fin_ip"
            echo "$fin_ip"
            break
        else
            echo "La IP final debe tener el último octeto mayor que la IP inicial."
        fi
    done
}