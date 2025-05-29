#!/bin/bash

echo "==== 1. Instalando Docker ===="
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt update
sudo apt install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER
echo "Por favor cierra sesión y vuelve a entrar para aplicar grupo docker."

echo "==== 2. Descargando imagen de Apache ===="
docker pull httpd
docker run -dit --name apache_test -p 8080:80 httpd

echo "==== 3. Modificando página por defecto ===="
docker exec -i apache_test bash << EOF
echo "<h1>It Works!</h1>" > /usr/local/apache2/htdocs/index.html
exit
EOF

ufw allow 8080/tcp

echo "Página modificada. Verifica en http://192.168.1.10:8080"

echo "==== 4. Creando imagen personalizada de Apache ===="
mkdir -p ~/apache_custom
cd ~/apache_custom

# Crear index.html
cat > index.html << HTML
<h1>Apache personalizado con Docker</h1>
HTML

# Crear Dockerfile
cat > Dockerfile << DOCKERFILE
FROM httpd
COPY index.html /usr/local/apache2/htdocs/index.html
DOCKERFILE

# Construir imagen y correr contenedor
docker build -t apache_custom .
docker run -dit --name apache_ready -p 8081:80 apache_custom

ufw allow 8081/tcp

echo "Contenedor personalizado corriendo en http://192.168.1.10:8081"

echo "==== 5. Preparando red y contenedores PostgreSQL ===="
docker network create red_interna

docker run -dit --name db1 --network red_interna -e POSTGRES_PASSWORD=1234 -e POSTGRES_DB=testdb postgres
docker run -dit --name db2 --network red_interna -e POSTGRES_PASSWORD=1234 -e POSTGRES_DB=testdb postgres

apt update && apt install -y postgresql-client

echo "PostgreSQL listo en red interna. Puedes conectarte entre ellos usando psql."

echo "Todo listo. Verifica tus servicios en:"
echo "   Apache default:    http://192.168.1.10:8080"
echo "   Apache personalizado: http://192.168.1.10:8081"
