# Función para verificar si una IP es válida
verificar_ip() {
    local ip=$1
    local regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    [[ $ip =~ $regex ]]
}

# Función para validar un dominio (solo .com)
verificar_dominio() {
    local dom=$1
    local regex="^[a-zA-Z0-9.-]+\.com$"

    [[ $dom =~ $regex ]]
}

# Pedir IP al usuario
while true; do
    read -p "Ingrese la dirección IP del servidor: " servidor_ip
    if verificar_ip "$servidor_ip"; then
        echo "IP válida: $servidor_ip"
        break
    else
        echo "Error: IP inválida. Intente nuevamente."
    fi
done

# Pedir dominio al usuario
while true; do
    read -p "Ingrese el dominio (debe terminar en .com): " dominio
    if verificar_dominio "$dominio"; then
        echo "Dominio válido: $dominio"
        break
    else
        echo "Error: Dominio inválido. Intente nuevamente."
    fi
done

# Extraer segmentos de la IP para la configuración inversa
IFS='.' read -r seg1 seg2 seg3 seg4 <<< "$servidor_ip"
ip_invertida="${seg3}.${seg2}.${seg1}"
ultimo_octeto="$seg4"

# Configurar red con Netplan
sudo tee /etc/netplan/50-cloud-init.yaml > /dev/null <<EOT
# This file is generated from information provided by the datasource.  Changes
# to it will not persist across an instance reboot.  To disable cloud-init's
# network configuration capabilities, write a file
# /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg with the following:
# network: {config: disabled}
network:
    ethernets:
        enp0s3:
            dhcp4: true
        enp0s8:
            addresses: [$servidor_ip/24]
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
    version: 2
EOT

# Aplicar configuración de red
sudo netplan apply

# Instalar BIND9
sudo apt-get update && sudo apt-get install -y bind9 bind9utils bind9-doc

# Configurar BIND9 (archivo de opciones)
cd /etc/bind
sudo tee /etc/bind/named.conf.options > /dev/null <<EOT
options {
	directory "/var/cache/bind";

	// If there is a firewall between you and nameservers you want
	// to talk to, you may need to fix the firewall to allow multiple
	// ports to talk.  See http://www.kb.cert.org/vuls/id/800113

	// If your ISP provided one or more IP addresses for stable 
	// nameservers, you probably want to use them as forwarders.  
	// Uncomment the following block, and insert the addresses replacing 
	// the all-0's placeholder.

        forwarders {
	     8.8.8.8;
        };

	//========================================================================
	// If BIND logs error messages about the root key being expired,
	// you will need to update your keys.  See https://www.isc.org/bind-keys
	//========================================================================
	dnssec-validation auto;

	listen-on-v6 { any; };
};
EOT

# Configurar BIND9 (archivo de zonas)
sudo tee /etc/bind/named.conf.local > /dev/null <<EOT
//
// Do any local configuration here
//
zone "$dominio" {
	type master;
	file "/etc/bind/db.$dominio";
};

zone "$ip_invertida.in-addr.arpa" {
	type master;
	file "/etc/bind/db.${ip_invertida}";
};
// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";
EOT

#Copio el archivo db.127 y le pongo db.nombre de la ip
cp /etc/bind/db.127 /etc/bind/db.${ip_invertida}
#Me meto a ese archivo que copie 
sudo tee /etc/bind/db.${ip_invertida} > /dev/null <<EOT
;
; BIND reverse data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	$dominio. root.$dominio. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$dominio.
$ultimo_octeto	IN	PTR	$dominio.
EOT


# Crear archivo de zona directa
cp /etc/bind/db.local /etc/bind/db.$dominio

#Me meto al archivo que copie 
sudo tee /etc/bind/db.$dominio > /dev/null <<EOT
;
; BIND data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	$dominio. root.$dominio. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$dominio.
@	IN	A	$servidor_ip
www	IN	CNAME	$dominio.
EOT

#Sobreescribo este archivo
sudo tee /etc/resolv.conf > /dev/null <<EOT
search $dominio.
domain $dominio.
nameserver $servidor_ip
options edns0 trust-ad
EOT

#Reinicio el servicio
service bind9 restart
#checo el status
service bind9 status





