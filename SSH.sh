
#Actualizar la lista de paquetes
apt-get update

#Instalar el servidor OpenSSH
sudo apt -y install openssh-server

#Habilitar el servicio SSH para que inicie automáticamente
sudo systemctl enable ssh

#Reiniciar el servicio SSH
sudo systemctl restart ssh

#Verificar el estado del servicio SSH
sudo systemctl status ssh

#Permitir conexiones SSH en el firewall
sudo ufw allow ssh

#Habilitar el firewall
sudo ufw enable 

