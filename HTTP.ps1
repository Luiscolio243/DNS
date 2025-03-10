# Script para instalar IIS, Lighttpd y Caddy en Windows Server

function Elegir-Version {
    param (
        [string]$Servicio,
        [string]$Url
    )
    
    Write-Host "Obteniendo versiones disponibles de $Servicio..."
    $Versiones = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Links | Where-Object { $_.href -match '\d+\.\d+\.\d+/' } | ForEach-Object { $_.href -replace '/$','' } | Sort-Object {[version]$_} -Descending
    
    if (-not $Versiones) {
        Write-Host "No se encontraron versiones disponibles para $Servicio."
        exit 1
    }
    
    Write-Host "Seleccione la versión de $($Servicio):"
    for ($i=0; $i -lt $Versiones.Count; $i++) {
        Write-Host "$($i+1). $($Versiones[$i])"
    }
    
    $Seleccion = Read-Host "Ingrese el número de la versión deseada"
    
    if ($Seleccion -match '^[0-9]+$' -and $Seleccion -gt 0 -and $Seleccion -le $Versiones.Count) {
        return $Versiones[$Seleccion - 1]
    } else {
        Write-Host "Opción inválida. Intente de nuevo."
        exit 1
    }
}

# Función para instalar IIS (Obligatorio en Windows)
function Instalar-IIS {
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar IIS"
    
    Write-Host "Instalando IIS..."
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    
    Write-Host "Configurando IIS en el puerto $Puerto..."
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\services\W3SVC\Parameters' -Name 'ListenOnlyList' -Value "*:$Puerto"
    Restart-Service W3SVC
    
    Write-Host "IIS instalado y configurado en el puerto $Puerto."
}

# Función para instalar Lighttpd
function Instalar-Lighttpd {
    $Version = Elegir-Version "Lighttpd" "https://download.lighttpd.net/lighttpd/releases-1.4.x/"
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Lighttpd"
    
    Write-Host "Descargando Lighttpd versión $Version..."
    Invoke-WebRequest -Uri "https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-$Version-win.zip" -OutFile "$env:TEMP\Lighttpd.zip"
    Expand-Archive -Path "$env:TEMP\Lighttpd.zip" -DestinationPath "C:\Lighttpd"
    
    (Get-Content "C:\Lighttpd\conf\lighttpd.conf") -replace 'server.port = 80', "server.port = $Puerto" | Set-Content "C:\Lighttpd\conf\lighttpd.conf"
    Start-Process -FilePath "C:\Lighttpd\lighttpd.exe" -NoNewWindow -Wait
    
    Write-Host "Lighttpd instalado y configurado en el puerto $Puerto."
}

# Función para instalar Caddy
function Instalar-Caddy {
    $Version = Elegir-Version "Caddy" "https://github.com/caddyserver/caddy/releases"
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Caddy"
    
    Write-Host "Descargando Caddy versión $Version..."
    Invoke-WebRequest -Uri "https://github.com/caddyserver/caddy/releases/download/v$Version/caddy_windows_amd64.zip" -OutFile "$env:TEMP\Caddy.zip"
    Expand-Archive -Path "$env:TEMP\Caddy.zip" -DestinationPath "C:\Caddy"
    
    (Get-Content "C:\Caddy\Caddyfile") -replace 'http://localhost', "http://localhost:$Puerto" | Set-Content "C:\Caddy\Caddyfile"
    Start-Process -FilePath "C:\Caddy\caddy.exe" -NoNewWindow -Wait
    
    Write-Host "Caddy instalado y configurado en el puerto $Puerto."
}

# Menú de selección de servicio
Write-Host "¿Qué servicio desea instalar? (IIS es obligatorio)"
Write-Host "1.- IIS (Obligatorio)"
Write-Host "2.- Lighttpd"
Write-Host "3.- Caddy"
Write-Host "4.- Salir"
$choice = Read-Host "Seleccione una opción (1-4)"

switch ($choice) {
    "1" { Instalar-IIS }
    "2" { Instalar-Lighttpd }
    "3" { Instalar-Caddy }
    "4" { Write-Host "Saliendo..."; exit 0 }
    default { Write-Host "Opción inválida. Saliendo..."; exit 1 }
}
