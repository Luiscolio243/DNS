#!/bin/bash
source "./variables_http.sh"
source "./instalar_dependenciashttp.sh"

conf_litespeed(){
    local port="$1"
    local version="$2"
    #echo "Descargando OpenLiteSpeed $version"

    cd /tmp
    # Variable URL para descargar la version
    #url="https://openlitespeed.org/packages/"$version".tgz"
    url="${url_litespeed_descargas}$version.tgz"

    wget -O litespeed.tgz "$url"
    #Extraer archivos
    tar -xzf litespeed.tgz > /dev/null 2>&1
    #Cambiar de directorio e instalar
    cd openlitespeed

    #Instalar openlitespeed
    sudo bash install.sh > /dev/null 2>&1

    # Modificar el puerto de escucha
    config="/usr/local/lsws/conf/httpd_config.conf"

    sudo grep -rl "8088" "/usr/local/lsws/conf" | while read file; do
        sudo sed -i "s/8088/$port/g" "$file"
    done

    echo "ServerName localhost" | sudo tee -a "$config"
    
    sudo systemctl start lshttpd
    sudo systemctl enable lshttpd

    sudo ufw allow $port/tcp
    
    # Reniciar el servicio
    sudo /usr/local/lsws/bin/lswsctrl restart
}

conf_apache(){
    local port="$1"
    local version="$2"
    #echo "Descargando Apache $version"

    #Descargar e instalar la versión seleccionada
    cd /tmp
    url="${url_apache_descargas}httpd-$version.tar.gz"
    wget "$url"
    tar -xzvf httpd-$version.tar.gz > /dev/null 2>&1
    cd httpd-$version

    #Configurar Apache para la instalación
    ./configure --prefix=/usr/local/apache2 --enable-so --enable-mods-shared=all --enable-ssl > /dev/null 2>&1
    #Compilar e instalar Apache
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1

    #Configurar el puerto
    sudo sed -i "s/Listen 80/Listen $port/" /usr/local/apache2/conf/httpd.conf 

    #Asegurarse de que la directiva 'ServerName' esté configurada
    echo "ServerName localhost" | sudo tee -a /usr/local/apache2/conf/httpd.conf 
            
    #Reiniciar Apache
    sudo /usr/local/apache2/bin/apachectl start 
    sudo ufw allow $port/tcp
}

conf_nginx(){
    local port="$1"
    local version="$2"
    #echo "Descargando Nginx $version"

    #Descargar e instalar la versión seleccionada
    cd /tmp
    url="${url_nginx_descargas}nginx-$version.tar.gz"
    wget -q "$url"
    #wget https://nginx.org/download/nginx-$version.tar.gz
    tar -xzvf nginx-$version.tar.gz > /dev/null 2>&1
    cd nginx-$version

    #Configurar Nginx para la instalación
    ./configure --prefix=/usr/local/nginx --with-http_ssl_module > /dev/null 2>&1

    #Compilar e instalar Nginx
    make > /dev/null 2>&1
    sudo make install > /dev/null 2>&1
    sudo sed -i "s/listen[[:space:]]*80/listen $port/" /usr/local/nginx/conf/nginx.conf
    sudo grep "listen" /usr/local/nginx/conf/nginx.conf

    #Iniciar Nginx
    sudo /usr/local/nginx/sbin/nginx 
    sudo ufw allow $port/tcp

}
