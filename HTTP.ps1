# Script para instalar IIS, Lighttpd y Caddy en Windows Server

function Elegir-Version {
    param (
        [string]$Servicio,
        [string]$Url
    )

    Write-Host "Obteniendo versiones disponibles de $Servicio..."
    
    $Headers = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }

    if ($Servicio -eq "Caddy") {
        $JsonData = Invoke-RestMethod -Uri $Url -Headers $Headers
        $Links = $JsonData | Select-Object -ExpandProperty tag_name
    } else {
        $Response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Headers $Headers
        $Links = $Response.Links | Select-Object -ExpandProperty href
    }

    $Versiones = $Links |
        Where-Object { $_ -match 'v?(\d+\.\d+\.\d+)' } |
        ForEach-Object { ($_ -match 'v?(\d+\.\d+\.\d+)')[1] } |
        Sort-Object {[version]$_} -Descending

    if (-not $Versiones) {
        Write-Host "No se encontraron versiones disponibles para $Servicio."
        exit 1
    }

    Write-Host "Seleccione la versión de $($Servicio):"
    for ($i = 0; $i -lt $Versiones.Count; $i++) {
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
    Write-Host "Lighttpd no tiene una versión oficial para Windows. Instalación cancelada."
    exit 1
}

# Función para instalar Caddy
function Instalar-Caddy {
    $LatestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/caddyserver/caddy/releases/latest" -Headers @{ 'User-Agent' = 'Mozilla/5.0' }
    $DownloadUrl = $LatestRelease.assets | Where-Object { $_.name -match 'windows_amd64.zip' } | Select-Object -ExpandProperty browser_download_url

    if (-not $DownloadUrl) {
        Write-Host "No se encontró una versión válida de Caddy para Windows."
        exit 1
    }
    
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Caddy"
    
    Write-Host "Descargando Caddy desde $DownloadUrl ..."
    Invoke-WebRequest -Uri $DownloadUrl -OutFile "$env:TEMP\Caddy.zip"
    Expand-Archive -Path "$env:TEMP\Caddy.zip" -DestinationPath "C:\Caddy"
    
    (Get-Content "C:\Caddy\Caddyfile") -replace 'http://localhost', "http://localhost:$Puerto" | Set-Content "C:\Caddy\Caddyfile"
    Start-Process -FilePath "C:\Caddy\caddy.exe" -NoNewWindow -Wait
    
    Write-Host "Caddy instalado y configurado en el puerto $Puerto."
}

# Menú de selección de servicio
Write-Host "¿Qué servicio desea instalar? (IIS es obligatorio)"
Write-Host "1.- IIS (Obligatorio)"
Write-Host "2.- Lighttpd (No disponible en Windows)"
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
