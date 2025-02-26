# Función para verificar si una IP es válida
function ValidarIP {
    param (
        [string]$direccionIP
    )
    $formatoValido = "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    return $direccionIP -match $formatoValido
}

# Función para validar un dominio 
function VerificarNombreDominio {
    param (
        [string]$nombreDominio
    )
    $patron = "\.com$"
    
    return $nombreDominio -match $patron
}

# Solicitar IP del servidor DNS
do {
    $direccionIP = Read-Host "Ingrese la IP del servidor DNS"
    if (ValidarIP $direccionIP) {
        Write-Host "Dirección IP válida: $direccionIP" -ForegroundColor Green
        break
    } else {
        Write-Host "IP inválida. Intente de nuevo." -ForegroundColor Red
    }
} while ($true)

# Solicitar dominio
do {
    $nombreDominio = Read-Host "Ingrese el nombre de dominio"
    if (VerificarNombreDominio $nombreDominio) {
        Write-Host "Dominio válido: $nombreDominio" -ForegroundColor Green
        break
    } else {
        Write-Host "El dominio debe terminar en '.com'. Intente nuevamente." -ForegroundColor Red
    }
} while ($true)

# Dividir la IP en segmentos y construir la IP invesa
$segmentos = $direccionIP -split '\.'
$segmentoTres = "$($segmentos[0]).$($segmentos[1]).$($segmentos[2])"
$ipReversa = "$($segmentos[2]).$($segmentos[1]).$($segmentos[0]).in-addr.arpa"

$subnetMask = "255.255.255.0"

# Configurar IP fija y DNS
netsh interface ipv4 set address name="Ethernet 2" static $direccionIP $subnetMask
netsh interface ipv4 set dns name="Ethernet 2" static 8.8.8.8

# Instalar servicio DNS
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Crear zonas DNS
Add-DnsServerPrimaryZone -Name "$nombreDominio" -ZoneFile "$nombreDominio.dns" -DynamicUpdate None -PassThru 
Add-DnsServerPrimaryZone -NetworkID "$segmentoTres.0/24" -ZoneFile "$ipReversa.dns" -DynamicUpdate None -PassThru 

# Verificar zonas creadas
Get-DnsServerZone 

# Agregar registros DNS
Add-DnsServerResourceRecordA -Name "www" -ZoneName "$nombreDominio" -IPv4Address "$direccionIP" -TimeToLive 01:00:00 -CreatePtr -PassThru 
Get-DnsServerResourceRecord -ZoneName "$nombreDominio" | Format-Table -AutoSize -Wrap 

# Configurar cliente DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress "$direccionIP"

# Configurar firewall para permitir ICMP
New-NetFirewallRule -DisplayName "Permitir Ping" -Direction Inbound -Protocol ICMPv4 -Action Allow

# Mostrar registros DNS
Get-DnsServerResourceRecord -ZoneName "$nombreDominio"

# Agregar otro registro DNS
Add-DnsServerResourceRecordA -Name "@" -ZoneName "$nombreDominio" -IPv4Address "$direccionIP" -TimeToLive 01:00:00 -PassThru
