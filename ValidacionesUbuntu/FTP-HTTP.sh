#!/bin/bash

listar_carpetas_ftp() {
    local ftp_user="ubuntu"
    local ftp_pass="1234"
    local ftp_ip="192.168.1.2"

    # Obtener listado crudo del FTP
    local listado=$(curl -s --user "$ftp_user:$ftp_pass" "ftp://$ftp_ip/")
    local carpetas=()

    while IFS= read -r linea; do
        # Extraer solo nombres de directorio del formato de 'ls'
        nombre=$(echo "$linea" | awk '{print $NF}')
        if [[ "$linea" == d* ]]; then  # Solo directorios
            carpetas+=("$nombre")
        fi
    done <<< "$listado"

    # Imprimir solo los nombres, uno por línea
    for carpeta in "${carpetas[@]}"; do
        echo "$carpeta"
    done
}

listar_archivos_ftp() {
    carpeta=$1
    
    local ftp_user="ubuntu"
    local ftp_pass="1234"
    local ftp_ip="192.168.1.2"

    curl -s --user "$ftp_user:$ftp_pass" "ftp://$ftp_ip/$carpeta/" | awk '{print $NF}'
}

descargar_y_descomprimir() {
    local carpeta=$1
    local archivo=$2
    local ip_ftp="192.168.1.2"
    local usuario="ubuntu"
    local contra="1234"
    local ruta_ftp="ftp://$ip_ftp/$carpeta/$archivo"

    echo "Descargando desde: $ruta_ftp"
    cd /tmp || exit 1

    # Descargar el archivo .tar.gz
    curl -s --user "$usuario:$contra" -O "$ruta_ftp"
    if [ ! -f "$archivo" ]; then
        echo "Error: No se pudo descargar el archivo."
        exit 1
    fi

    echo "Descomprimiendo archivo .tar.gz..."
    tar -xzvf "$archivo" > /dev/null 2>&1 || { echo "Error al descomprimir el archivo."; exit 1; }

    # Detectar carpeta extraída
    dir_extraido=$(tar -tzf "$archivo" | head -1 | cut -f1 -d"/")
    #echo "Descarga y descompresión completadas. Carpeta extraída: $dir_extraido"
}

configurar_apache() {
    local port="$1"
    local version="$2"
    local ssl="$3"
    local ip="192.168.1.2"  # Puedes ajustar o pedir al usuario

    cd /tmp/httpd-$version || { echo "No se encontró /tmp/httpd-$version"; exit 1; }

    #echo "Compilando e instalando Apache..."
    ./configure --prefix=/usr/local/apache2 --enable-so --enable-mods-shared=all --enable-ssl > /dev/null 2>&1
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1

    #echo "Configurando el puerto $port en Apache..."
    sudo sed -i "s/Listen 80/Listen $port/" /usr/local/apache2/conf/httpd.conf 
    echo "ServerName localhost" | sudo tee -a /usr/local/apache2/conf/httpd.conf 

    echo "Iniciando Apache en el puerto $port..."
    sudo /usr/local/apache2/bin/apachectl start 
    sudo ufw allow "$port"/tcp

    if [[ "$ssl" == "s" ]]; then
        #echo "Configurando SSL en Apache..."
        sudo sed -i 's|^#LoadModule ssl_module modules/mod_ssl.so|LoadModule ssl_module modules/mod_ssl.so|' /usr/local/apache2/conf/httpd.conf

        # Genera el certificado SSL
        crear_certificado_ssl "$ip"

        # Crear el archivo httpd-ssl.conf
        sudo tee /usr/local/apache2/conf/extra/httpd-ssl.conf > /dev/null <<EOL
<VirtualHost *:$port>
    ServerName $ip
    SSLEngine on
    SSLCertificateFile /etc/ssl/localcerts/selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/localcerts/selfsigned.key
</VirtualHost>
EOL

        # Incluir SSL en httpd.conf
        sudo sed -i "s|#Include conf/extra/httpd-ssl.conf|Include conf/extra/httpd-ssl.conf|" /usr/local/apache2/conf/httpd.conf
        sudo /usr/local/apache2/bin/apachectl restart
        echo "SSL configurado y Apache reiniciado en el puerto $port"
    fi

    echo "Apache configurado correctamente en el puerto $port"
}

configurar_openlitespeed() {
    port=$1
    version=$2
    ssl=$3
    ip="192.168.1.10"  # Puedes modificarla o pasarla como parámetro si quieres

    cd /tmp || exit
    if [[ ! -d "openlitespeed" ]]; then
        echo "No se encontró la carpeta openlitespeed"
        exit 1
    fi

    cd "openlitespeed" || exit
    #echo "Instalando OpenLiteSpeed versión $version..."

    # Ejecutar el instalador
    sudo bash install.sh > /dev/null 2>&1

    config="/usr/local/lsws/conf/httpd_config.conf"

    # Cambiar el puerto en todas las configuraciones que usen 8088
    sudo grep -rl "8088" "/usr/local/lsws/conf" | while read -r file; do
        sudo sed -i "s/8088/$port/g" "$file"
    done

    echo "ServerName localhost" | sudo tee -a "$config"

    # Iniciar y habilitar el servicio
    sudo systemctl start lshttpd
    sudo systemctl enable lshttpd

    # Permitir el puerto en el firewall
    sudo ufw allow "$port"/tcp

    # Reiniciar el servicio
    sudo /usr/local/lsws/bin/lswsctrl restart

    # Configuración SSL si el usuario quiere
    if [[ "$ssl" == "s" ]]; then
        crear_certificado_ssl "$ip"

        sudo tee -a /usr/local/lsws/conf/httpd_config.conf > /dev/null <<EOL
listener SSL {
    address *:$port
    secure 1
    map Example *
    keyFile /etc/ssl/localcerts/selfsigned.key
    certFile /etc/ssl/localcerts/selfsigned.crt
}
EOL
        sudo /usr/local/lsws/bin/lswsctrl restart
        echo "SSL configurado y OpenLiteSpeed reiniciado en el puerto $port"
    fi

    echo "OpenLiteSpeed configurado correctamente en el puerto $port"
}

configurar_nginx() {
    local port=$1
    local version=$2
    local ssl=$3
    local ip="192.168.1.10"  # IP para SSL

    #echo "Descomprimiendo y configurando NGINX versión $version..."
    cd /tmp || exit 1

    # Descomprimir
    tar -xzvf "nginx-$version.tar.gz" > /dev/null 2>&1
    if [[ ! -d "nginx-$version" ]]; then
        echo "No se encontró la carpeta nginx-$version"
        exit 1
    fi

    cd "nginx-$version"

    # Configuración, compilación e instalación
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null 2>&1
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1

    # Cambiar puerto en la configuración
    sudo sed -i "s/listen[[:space:]]*80;/listen $port;/" /usr/local/nginx/conf/nginx.conf
    sudo grep "listen" /usr/local/nginx/conf/nginx.conf

    # Iniciar NGINX
    sudo /usr/local/nginx/sbin/nginx
    sudo ufw allow "$port"/tcp

    # SSL opcional
    if [[ "$ssl" == "s" ]]; then
        crear_certificado_ssl "$ip"
        sudo tee /usr/local/nginx/conf/nginx.conf > /dev/null <<EOL
events {
    worker_connections 1024;
}

http {
    server {
        listen $port ssl;
        server_name $ip;

        ssl_certificate /etc/ssl/localcerts/selfsigned.crt;
        ssl_certificate_key /etc/ssl/localcerts/selfsigned.key;
    }
}
EOL
        sudo /usr/local/nginx/sbin/nginx -s reload
        echo "NGINX configurado con SSL en el puerto $port"
    fi

    echo "NGINX instalado y configurado correctamente en el puerto $port"
}

