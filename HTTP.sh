#!/bin/bash

obtener_versiones() {
    local servicio="$1"
    local url="$2"
    
    echo "Obteniendo versiones disponibles de $servicio..."
    
    # Descargar el HTML de la página
    contenido=$(curl -s "$url" || wget -qO- "$url")

    # Extraer versiones dependiendo del servicio
    case $servicio in
        "Apache")
            # Apache HTTPD almacena las versiones en subdirectorios numerados
            versiones=( $(echo "$contenido" | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | uniq) )
            ;;
        "Tomcat")
            # Tomcat usa directorios con versiones en la página de descargas
            versiones=( $(echo "$contenido" | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | uniq) )
            ;;
        "Nginx")
            # Nginx almacena los paquetes en formato nginx-X.Y.Z.tar.gz
            versiones=( $(echo "$contenido" | grep -oP 'nginx-\d+\.\d+\.\d+(?=\.tar\.gz)' | sed 's/nginx-//' | sort -V | uniq) )
            ;;
    esac

    # Mostrar el contenido descargado si no se encuentran versiones (depuración)
    if [ ${#versiones[@]} -eq 0 ]; then
        echo "No se encontraron versiones disponibles para $servicio."
        echo "Contenido obtenido (primeras 20 líneas):"
        echo "$contenido" | head -n 20  # Mostrar las primeras 20 líneas para depuración
        exit 1
    fi

    # Mostrar versiones en orden de la más antigua a la más nueva
    echo "Seleccione la versión de $servicio (de la más antigua a la más nueva):"
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
    obtener_versiones "Apache" "https://downloads.apache.org/httpd/"
    read -p "Ingrese el puerto en el que desea configurar Apache: " puerto
    sudo apt update && sudo apt install -y apache2
    sudo sed -i "s/Listen 80/Listen $puerto/g" /etc/apache2/ports.conf
    sudo systemctl restart apache2
    echo "Apache instalado y configurado en el puerto $puerto."
}

# Función para instalar Tomcat
instalar_tomcat() {
    obtener_versiones "Tomcat" "https://downloads.apache.org/tomcat/"
    read -p "Ingrese el puerto en el que desea configurar Tomcat: " puerto
    sudo apt update && sudo apt install -y tomcat9
    sudo sed -i "s/port=\"8080\"/port=\"$puerto\"/g" /etc/tomcat9/server.xml
    sudo systemctl restart tomcat9
    echo "Tomcat instalado y configurado en el puerto $puerto."
}

# Función para instalar Nginx
instalar_nginx() {
    obtener_versiones "Nginx" "http://nginx.org/download/"
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
