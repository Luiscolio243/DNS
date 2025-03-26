#!/bin/bash
menu_http(){
    echo "= MENU HTTP ="
    echo "1. Apache"
    echo "2. OpenLiteSpeed"
    echo "3. Nginx"
    echo "4. Regresar"
}

menu_http2(){
    local service="$1"
    local stable="$2"
    local mainline="$3"
    echo "$service"
    
    if [ "$service" = "Apache" ]; then
        echo "1. Versión estable $stable"
        echo "2. Regresar"
    elif [ "$service" = "Nginx" ] || [ "$service" = "OpenLiteSpeed" ]; then
        echo "1. Versión estable $stable"
        echo "2. Versión de desarrollo $mainline"
        echo "3. Regresar"
    else 
        echo "Opción no válida"
        exit 1
    fi
}