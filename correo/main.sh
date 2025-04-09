# !/bin/bash

source "./conf_dns.sh"
source "./conf_correo.sh"
source "./crear_user.sh"
source "./solicitar_user.sh"
source "./verificar_servicio.sh"

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

echo " Correo "
sudo apt update
# Configurar servidor DNS 
#echo "Configurando servidor DNS en paulook.com...."
ip_fija="192.168.1.10"
dominio="luiscolio.com"

conf_dns "$ip_fija" "$dominio"

# Establecemos el nombre de host del sistema, es decir, nuestro servidor DN
sudo hostnamectl set-hostname "$dominio"

# Verifica antes de instalar Apache
if ! verificar_servicio "apache2"; then
    conf_correo
else
    echo "Servicio de correo ya configurado."
fi


# Muestra el nombre de correo configurado en el sistema
cat /etc/mailname

while true; do
    #echo "=== MENU PRINCIPAL ==="
    echo "1. Crear usuario"
    echo "2. Salir"
    read -p "Seleccione una opcion: " opc

    if [ "$opc" -eq 1 ]; then
        echo "Nombre de usuario:"
        user=$(solicitar_user)
        crear_user "$user" 
    elif [ "$opc" -eq 2 ]; then
        #echo "Saliendo..."
        exit 0
    else
        echo "La opcion no es valida"
    fi
done




