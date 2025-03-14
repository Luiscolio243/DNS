#!/bin/bash
solicitar_ver() {
    local service="$1"
    local ver
    while true; do
        read ver
        if [ "$service" = "Apache" ] && [[ "$ver" =~ ^[1-2]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        elif [ "$service" = "Nginx" ] && [[ "$ver" =~ ^[1-3]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        elif [ "$service" = "OpenLiteSpeed" ] && [[ "$ver" =~ ^[1-3]$ ]]; then
            echo "$ver"  # Solo devuelve la opción válida
            return
        else
            echo "No es valido" >&2  
        fi
    done
}