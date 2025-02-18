# Instalar el rol de DHCP con herramientas de administración
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Verificar si la instalación fue exitosa
if ((Get-WindowsFeature -Name DHCP).Installed) {
    Write-Host "El rol de DHCP se ha instalado correctamente."
} else {
    Write-Host "Error en la instalación del rol DHCP." -ForegroundColor Red
    exit
}

# Autorizar el servidor DHCP (si está en un dominio)
Add-DhcpServerInDC -DnsName (hostname) -IPAddress (Get-NetIPAddress -AddressFamily IPv4 | Select-Object -First 1 -ExpandProperty IPAddress)

# Crear un ámbito (scope) DHCP
Add-DhcpServerv4Scope -Name "Red LAN" -StartRange 192.168.1.100 -EndRange 192.168.1.200 `
-MaskLength 24 -State Active -LeaseDuration 1.00:00:00

# Reiniciar el servicio DHCP para aplicar los cambios
Restart-Service dhcpserver

Write-Host "Configuración de DHCP completada correctamente." -ForegroundColor Green
