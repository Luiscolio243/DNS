# Función para configurar el servidor DHCP
function ConfigurarDHCP {
    param (
        [string]$ip_servidor,
        [string]$ip_inicio,
        [string]$ip_fin
    )
    # Calcula la subred y la puerta de enlace basada en la IP del servidor
    $subred = ($ip_servidor -split '\.')[0..2] -join '.' + ".0"
    $puerta_enlace = ($ip_servidor -split '\.')[0..2] -join '.' + ".1"
    $mascara = "255.255.255.0"

    # Muestra la configuración generada
    Write-Host "Configuración completa:"
    Write-Host "Servidor DHCP: $ip_servidor"
    Write-Host "Rango de IPs: $ip_inicio - $ip_fin"
    Write-Host "Subred: $subred"
    Write-Host "Puerta de enlace: $puerta_enlace"

    # Configura la IP estática en la interfaz de red
    netsh interface ipv4 set address name="Ethernet 2" static $ip_servidor $mascara
    
    # Instala la característica de servidor DHCP en Windows
    Install-WindowsFeature DHCP -IncludeManagementTools
    
    # Crea un nuevo ámbito DHCP con el rango especificado
    Add-DhcpServerv4Scope -Name "RedLocal" -StartRange $ip_inicio -EndRange $ip_fin -SubnetMask $mascara
    
    # Reinicia el servicio DHCP
    Restart-Service -Name DHCPServer
    
    # Agrega una regla de firewall para permitir ping entrante
    New-NetFirewallRule -DisplayName "Permitir ping entrante" -Direction Inbound -Protocol ICMPv4 -Action Allow
}