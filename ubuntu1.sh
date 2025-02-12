# Funciones 
Validar-IP() { 
    local ip_address=$1 
    local valid_format="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0
    9]|[01]?[0-9][0-9]?)$"

    if [[ $ip_address =~ $valid_format ]]; then 
        return 0 
    else 
        return 1 
    fi 
} 

Validar-Dominio() { 
    local domain=$1 
    local valid_format="\.com$"

    if [[ $domain =~ $valid_format ]]; then 
        return 0 
    else 
        return 1 
    fi 
}

# Solicitar la direccion IP del servidor DNS 
while true; do 
    read -p "Ingrese la direccion IP del servidor DNS: " ip_address 
    if Validar-IP "$ip_address"; then 
        echo "¡Dirección IP válida ingresada: $ip_address!" 
        break 
    else 
        echo "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente." 
    fi 
done 

# Solicitar el dominio
while true; do 
    read -p "Ingrese el dominio: " domain 
    if Validar-Dominio "$domain"; then 
        echo "¡Dominio válido ingresado: $domain!" 
        break 
    else 
    echo "El dominio ingresado no es válido o no termina con '.com'. Por favor, 
    inténtelo nuevamente." 
    fi 
done 

IFS='.' read -r o1 o2 o3 o4 <<< "$ip_address"
reverse_ip="${o3}.${o2}.${o1}"
last_octet="$o4"

#Entraremos a ese arhivo para modificar la ip y agregar cosas
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
            addresses: [$ip_address/24]
            nameservers:
              addresses: [8.8.8.8, 1.1.1.1]
    version: 2
EOT
#comando para que se guarde
sudo netplan apply

#Instalar bind9
sudo apt-get update && sudo apt-get install -y bind9 bind9utils bind9-doc

#sobreescribir sobre este archivo
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

#sobreescribir este archivo para el dominio y la ip inversa
sudo tee /etc/bind/named.conf.local > /dev/null <<EOT
//
// Do any local configuration here
//
zone "$domain" {
	type master;
	file "/etc/bind/db.$domain";
};

zone "$reverse_ip.in-addr.arpa" {
	type master;
	file "/etc/bind/db.${reverse_ip}";
};
// Consider adding the 1918 zones here, if they are not used in your
// organization
//include "/etc/bind/zones.rfc1918";
EOT

#Copio el archivo db.127 y le pongo db.nombre de la ip
cp /etc/bind/db.127 /etc/bind/db.${reverse_ip}
#Me meto a ese archivo que copie 
sudo tee /etc/bind/db.${reverse_ip} > /dev/null <<EOT
;
; BIND reverse data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	$domain. root.$domain. (
			      1		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$domain.
$last_octet	IN	PTR	$domain.
EOT

#Copio bd.local y le pongo db.nombre del domino
cp /etc/bind/db.local /etc/bind/db.$domain

#Me meto al archivo que copie 
sudo tee /etc/bind/db.$domain > /dev/null <<EOT
;
; BIND data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	$domain. root.$domain. (
			      2		; Serial
			 604800		; Refresh
			  86400		; Retry
			2419200		; Expire
			 604800 )	; Negative Cache TTL
;
@	IN	NS	$domain.
@	IN	A	$ip_address
www	IN	CNAME	$domain.
EOT

#Sobreescribo este archivo
sudo tee /etc/resolv.conf > /dev/null <<EOT
search $domain.
domain $domain.
nameserver $ip_address
options edns0 trust-ad
EOT

#Reinicio el servicio
service bind9 restart
#checo el status
service bind9 status

nslookup $domain
nslookup www.$domain
nslookup $ip_address