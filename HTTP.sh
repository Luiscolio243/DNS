#!/bin/bash

# Función para obtener todas las versiones disponibles dinámicamente
elegir_version() {
    local servicio="$1"
    declare -a versiones

    case "$servicio" in
        "Apache")
            versiones=("1.0.0" "1.1.1" "1.2.0" "1.3.0" "1.3.42" "2.0.0" "2.0.40" "2.0.44" "2.0.48" "2.0.52" "2.0.55" "2.0.59" "2.0.65" "2.2.0" "2.2.8" "2.2.11" "2.2.14" "2.2.17" "2.2.19" "2.2.21" "2.2.22" "2.2.23" "2.2.24" "2.2.25" "2.2.26" "2.2.29" "2.2.31" "2.2.32" "2.2.33" "2.2.34" "2.4.0" "2.4.1" "2.4.2" "2.4.3" "2.4.4" "2.4.6" "2.4.7" "2.4.9" "2.4.10" "2.4.12" "2.4.16" "2.4.17" "2.4.18" "2.4.20" "2.4.23" "2.4.25" "2.4.27" "2.4.29" "2.4.33" "2.4.34" "2.4.35" "2.4.37" "2.4.38" "2.4.39" "2.4.41" "2.4.43" "2.4.46" "2.4.48" "2.4.51" "2.4.54" "2.4.56" "2.4.57" "2.4.58" "2.4.59" "2.4.60" "2.4.61" "2.4.62" "2.4.63")
            ;;
        "Tomcat")
            versiones=("4.0" "5.0" "5.5" "6.0" "7.0" "8.0" "8.5" "9.0.0" "9.0.10" "9.0.20" "9.0.30" "9.0.40" "9.0.50" "9.0.60" "9.0.70" "9.0.80" "10.0.0" "10.0.10" "10.0.20" "10.0.30" "10.1.0" "10.1.10")
            ;;
        "Nginx")
            versiones=("0.1" "0.2" "0.3" "0.4" "0.5" "0.6" "0.7" "0.8" "0.9" "1.0" "1.1" "1.2" "1.3" "1.4" "1.5" "1.6" "1.7" "1.8" "1.9" "1.10" "1.11" "1.12" "1.13" "1.14" "1.15" "1.16" "1.17" "1.18" "1.19" "1.20" "1.21" "1.22" "1.23" "1.24" "1.25")
            ;;
        *)
            echo "Servicio no reconocido"
            exit 1
            ;;
    esac
    
    echo "Seleccione la versión de $servicio:"
    select version in "${versiones[@]}"; do
        if [[ -n "$version" ]]; then
            echo "Seleccionó la versión $version"
            break
        else
            echo "Opción inválida. Intente de nuevo."
        fi
    done
}

# Función para instalar Apache
instalar_apache() {
    elegir_version "Apache"
    read -p "Ingrese el puerto en el que desea configurar Apache: " puerto
    sudo apt update && sudo apt install -y apache2
    sudo sed -i "s/Listen 80/Listen $puerto/g" /etc/apache2/ports.conf
    sudo systemctl restart apache2
    echo "Apache instalado y configurado en el puerto $puerto."
}

# Función para instalar Tomcat
instalar_tomcat() {
    elegir_version "Tomcat"
    read -p "Ingrese el puerto en el que desea configurar Tomcat: " puerto
    sudo apt update && sudo apt install -y tomcat9
    sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" /etc/tomcat9/server.xml
    sudo systemctl restart tomcat9
    echo "Tomcat instalado y configurado en el puerto $puerto."
}

# Función para instalar Nginx
instalar_nginx() {
    elegir_version "Nginx"
    read -p "Ingrese el puerto en el que desea configurar Nginx: " puerto
    sudo apt update && sudo apt install -y nginx
    sudo sed -i "s/listen 80;/listen $puerto;/g" /etc/nginx/sites-available/default
    sudo systemctl restart nginx
    echo "Nginx instalado y configurado en el puerto $puerto."
}

# Menú de selección de servicio
echo "¿Qué servicio desea instalar?"
echo "1.- Apache"
echo "2.- Tomcat"
echo "3.- Nginx"
echo "4.- Salir"
read -p "Seleccione una opción (1-4): " choice

case $choice in
    1) instalar_apache ;;
    2) instalar_tomcat ;;
    3) instalar_nginx ;;
    4) echo "Saliendo..."; exit 0 ;;
    *) echo "Opción inválida. Saliendo..."; exit 1 ;;
esac
