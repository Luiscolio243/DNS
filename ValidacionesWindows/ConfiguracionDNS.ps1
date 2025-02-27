# Función para instalar el servicio DNS
function InstalarServicioDNS {
    Install-WindowsFeature -Name DNS -IncludeManagementTools
}

# Función para crear zonas DNS
function CrearZonasDNS {
    param (
        [string]$nombreDominio,
        [string]$ipReversa
    )
    Add-DnsServerPrimaryZone -Name "$nombreDominio" -ZoneFile "$nombreDominio.dns" -DynamicUpdate None -PassThru 
    Add-DnsServerPrimaryZone -NetworkID "$segmentoTres.0/24" -ZoneFile "$ipReversa.dns" -DynamicUpdate None -PassThru 
}

# Función para agregar registros DNS
function AgregarRegistrosDNS {
    param (
        [string]$nombreDominio,
        [string]$direccionIP
    )
    Add-DnsServerResourceRecordA -Name "www" -ZoneName "$nombreDominio" -IPv4Address "$direccionIP" -TimeToLive 01:00:00 -CreatePtr -PassThru 
    Add-DnsServerResourceRecordA -Name "@" -ZoneName "$nombreDominio" -IPv4Address "$direccionIP" -TimeToLive 01:00:00 -PassThru
}

# Función para configurar el cliente DNS
function ConfigurarClienteDNS {
    param (
        [string]$direccionIP
    )
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddress "$direccionIP"
}

# Función para mostrar registros DNS
function MostrarRegistrosDNS {
    param (
        [string]$nombreDominio
    )
    Get-DnsServerResourceRecord -ZoneName "$nombreDominio" | Format-Table -AutoSize -Wrap 
}