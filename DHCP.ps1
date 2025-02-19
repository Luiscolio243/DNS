# Función para validar una dirección IP
function ValidarIP {
    param (
        [string]$ip
    )
    # Validar direcciones IPv4
    $patron = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    return $ip -match $patron
}

# Función para solicitar una dirección IP válida al usuario
function ObtenerIPValida {
    param (
        [string]$mensaje
    )
    while ($true) {
        $ip = Read-Host $mensaje
        if (Validar-IP -ip $ip) {
            Write-Host "¡Dirección IP válida ingresada: $ip!"
            return $ip
        } else {
            Write-Host "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente."
        }
    }
}

# Función para obtener un rango de IP válido
function ObtenerRangoValido {
    param (
        [string]$ip_inicio
    )
    while ($true) {
        # Solicita la IP final del rango
        $ip_fin = Obtener-IPValida -mensaje "Ingrese la IP de fin del rango DHCP"
        
        # Extrae el último octeto de las IPs de inicio y fin
        $octeto_fin = [int]($ip_fin -split '\.')[3]
        $octeto_inicio = [int]($ip_inicio -split '\.')[3]

        # Verifica que la IP de fin tenga un último octeto mayor que la de inicio
        if ($octeto_fin -gt $octeto_inicio) {
            Write-Host "IP de fin válida: $ip_fin"
            return $ip_fin
        } else {
            Write-Host "La IP final debe tener el último octeto mayor que la IP inicial."
        }
    }
}

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
    
    # Excluye la IP del servidor del rango asignado por DHCP
    Add-DhcpServerv4ExclusionRange -ScopeId $subred -StartRange $ip_servidor -EndRange $ip_servidor
    
    # Reinicia el servicio DHCP
    Restart-Service -Name DHCPServer
    
    # Agrega una regla de firewall para permitir ping entrante
    New-NetFirewallRule -DisplayName "Permitir ping entrante" -Direction Inbound -Protocol ICMPv4 -Action Allow
}

# Ejecución principal del script
$ip_servidor = Obtener-IPValida -mensaje "Ingrese la dirección IP del servidor DNS"
$ip_inicio = Obtener-IPValida -mensaje "Ingrese la IP de inicio del rango DHCP"
$ip_fin = Obtener-RangoValido -ip_inicio $ip_inicio

# Llama a la función para configurar el DHCP
Configurar-DHCP -ip_servidor $ip_servidor -ip_inicio $ip_inicio -ip_fin $ip_fin
