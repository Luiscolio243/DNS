function Configurar-IP {
    param (
        [string]$ip_address
    )
    $mascara = "255.255.255.0"
    netsh interface ipv4 set address name="Ethernet 2" static $ip_address $mascara
    Write-Host "IP configurada correctamente en $ip_address" -ForegroundColor Green
}

Export-ModuleMember -Function Configurar-IP