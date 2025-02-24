
apt-get update

sudo apt -y install openssh-server

sudo systemctl enable ssh

sudo systemctl restart ssh

sudo systemctl status ssh

sudo ufw allow ssh

sudo ufw enable 

