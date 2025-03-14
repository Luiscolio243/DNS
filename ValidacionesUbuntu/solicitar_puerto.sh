#!/bin/bash
solicitar_puerto() {
    local port
    local puertos_reservados=(21 22 23 25 53 110 143 161 162 389 443 465 993 995 1 7 9 11 13 15 17 19 137 138 139 1433 1434 1521 2049 3128 3306 3389 5432 6000 6379 6660 6661 6662 6663 6664 6665 6666 6667 6668 6669 27017 8000 8080 8888)
    
    while true; do
        read -p "Puerto: " port

        [[ -z "$port" ]] && return

        # Verificar si el input es un número y está en el rango permitido
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo "Debe estar entre 1 y 65535" >&2  

        # Verificar si el puerto está en la lista de reservados
        elif [[ " ${puertos_reservados[*]} " =~ " $port " ]]; then
            echo "El puerto está reservado" >&2

        # Verificar si el puerto ya está en uso con ss
        elif ss -tuln | grep -q ":$port "; then
            echo "El puerto lo estan usando" >&2

        else 
            echo "$port"
            return
        fi
    done
}