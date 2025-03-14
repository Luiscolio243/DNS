#!/bin/bash
menu_http(){
    echo "HTTP "
    echo "1 Nginx"
    echo "2 Apache"
    echo "3 OpenLiteSpeed"
    echo "4 Salir"
}

menu_http2(){
    local service="$1"
    local stable="$2"
    local mainline="$3"
    echo "$service"
    
    if [ "$service" = "Apache" ]; then
        echo "1 Versión estable $stable"
        echo "2 Regresar"
    elif [ "$service" = "Nginx" ] || [ "$service" = "OpenLiteSpeed" ]; then
        echo "1 Versión estable $stable"
        echo "2 Versión de desarrollo $mainline"
        echo "3 Regresar"
    else 
        echo "No es valido"
        exit 1
    fi
}