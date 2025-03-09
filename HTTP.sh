#!/bin/bash

# Función para mostrar las versiones disponibles dinámicamente
elegir_version() {
    local servicio="$1"
    local -n versiones="$2"
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
    local versiones_apache=("2.4.58" "2.4.1")
    elegir_version "Apache" versiones_apache
    read -p "Ingrese el puerto en el que desea configurar Apache: " puerto
    sudo apt update && sudo apt install -y apache2
    sudo sed -i "s/Listen 80/Listen $puerto/g" /etc/apache2/ports.conf
    sudo systemctl restart apache2
    echo "Apache instalado y configurado en el puerto $puerto."
}

# Función para instalar Tomcat
instalar_tomcat() {
    local versiones_tomcat=("9.0.80" "10.1.10")
    elegir_version "Tomcat" versiones_tomcat
    read -p "Ingrese el puerto en el que desea configurar Tomcat: " puerto
    sudo apt update && sudo apt install -y tomcat9
    sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" /etc/tomcat9/server.xml
    sudo systemctl restart tomcat9
    echo "Tomcat instalado y configurado en el puerto $puerto."
}

# Función para instalar Nginx
instalar_nginx() {
    local versiones_nginx=("1.22.1" "1.25.2")
    elegir_version "Nginx" versiones_nginx
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
