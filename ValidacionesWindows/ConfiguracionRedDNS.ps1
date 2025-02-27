# Función para configurar la IP estática y el DNS
function ConfigurarIPyDNS {
    param (
        [string]$direccionIP,
        [string]$subnetMask
    )
    # Configurar IP fija y DNS
    netsh interface ipv4 set address name="Ethernet 2" static $direccionIP $subnetMask
    netsh interface ipv4 set dns name="Ethernet 2" static 8.8.8.8
}

# Función para configurar el firewall para permitir ICMP
function ConfigurarFirewall {
    New-NetFirewallRule -DisplayName "Permitir Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow
}