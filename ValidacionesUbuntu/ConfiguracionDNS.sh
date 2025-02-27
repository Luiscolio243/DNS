#!/bin/bash

# Función para instalar BIND9
InstalarBIND9() {
    sudo apt-get update && sudo apt-get install -y bind9 bind9utils bind9-doc
}

# Función para configurar named.conf.options
ConfigurarNamedOptions() {
    sudo tee /etc/bind/named.conf.options > /dev/null <<EOT
options {
    directory "/var/cache/bind";
    forwarders {
        8.8.8.8;
    };
    dnssec-validation auto;
    listen-on-v6 { any; };
};
EOT
}

# Función para configurar named.conf.local
ConfigurarNamedLocal() {
    local domain=$1
    local reverse_ip=$2
    sudo tee /etc/bind/named.conf.local > /dev/null <<EOT
zone "$domain" {
    type master;
    file "/etc/bind/db.$domain";
};

zone "$reverse_ip.in-addr.arpa" {
    type master;
    file "/etc/bind/db.${reverse_ip}";
};
EOT
}

# Función para configurar el archivo de zona inversa
ConfigurarZonaInversa() {
    local reverse_ip=$1
    local domain=$2
    local last_octet=$3
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
}

# Función para configurar el archivo de zona directa
ConfigurarZonaDirecta() {
    local domain=$1
    local ip_address=$2
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
}

# Función para configurar resolv.conf
ConfigurarResolvConf() {
    local domain=$1
    local ip_address=$2
    sudo tee /etc/resolv.conf > /dev/null <<EOT
search $domain.
domain $domain.
nameserver $ip_address
options edns0 trust-ad
EOT
}

# Función para reiniciar BIND9
ReiniciarBIND9() {
    sudo service bind9 restart
    sudo service bind9 status
}

# Función para verificar la configuración DNS
VerificarDNS() {
    local domain=$1
    local ip_address=$2
    nslookup $domain
    nslookup www.$domain
    nslookup $ip_address
}