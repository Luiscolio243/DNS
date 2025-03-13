#!/bin/bash
source "./variables_http.sh"

obtener_version(){
    local service="$1"
    case "$service" in
        Apache)
            versions=$(curl -s "$url_apache" |  grep -oP '(?<=Apache HTTP Server )\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        Nginx)
            versions=$(curl -s "$url_nginx" |  grep -oP '(?<=nginx-)\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        OpenLiteSpeed)
            versions=$(curl -s "$url_litespeed" | grep -oP 'openlitespeed-\d+\.\d+\.\d+' | sort -V | uniq)
            ;;
        *)
            echo "Servicio no soportado"
            exit 1
            ;;
    esac

    echo "$versions"
}