
# Función para obtener versiones de IIS en Windows Server
function Get-IISVersions {
    Write-Host "`n🔹 Versiones de IIS disponibles en Windows Server:"
    $versions = @(
        "IIS 10.0 (Windows Server 2016, 2019, 2022)",
        "IIS 8.5  (Windows Server 2012 R2)",
        "IIS 8.0  (Windows Server 2012)",
        "IIS 7.5  (Windows Server 2008 R2)"
    )
    for ($i = 0; $i -lt $versions.Count; $i++) {
        Write-Host "$($i+1). $($versions[$i])"
    }
    return $versions
}

# Función para instalar IIS según la versión seleccionada
function Install-IIS {
    $versions = Get-IISVersions
    do {
        $choice = Read-Host "Ingrese el número de la versión de IIS que desea instalar"
        $valid = ($choice -match '^\d+$') -and ($choice -ge 1) -and ($choice -le $versions.Count)
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)

    $selectedVersion = $versions[$choice - 1]
    Write-Host "Instalando $selectedVersion..."

    if ($selectedVersion -match "IIS 10.0") {
        Install-WindowsFeature -name Web-Server -IncludeManagementTools
    } else {
        Write-Host "⚠ No es posible instalar versiones anteriores a IIS 10.0 automáticamente. Debe descargarlas manualmente."
    }

    Write-Host " Instalación completada para $selectedVersion."
}

# Función para obtener versiones de XAMPP ordenadas de más nueva a más vieja
function Get-XAMPPVersions {
    Write-Host "Obteniendo versiones de XAMPP..."
    $url = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $versions = $html.Links | Where-Object { $_.href -match 'XAMPP%20Windows/(\d+\.\d+\.\d+)/' } | ForEach-Object { $_.href -replace 'XAMPP%20Windows/|/', '' }
    $versions = $versions | Sort-Object { [version]$_ } -Descending
    return $versions
}

# Función para instalar XAMPP
function Install-XAMPP {
    $versions = Get-XAMPPVersions
    if ($versions.Count -eq 0) {
        Write-Host " No se encontraron versiones de XAMPP disponibles. Abortando..."
        exit
    }

    $selectedVersion = Select-Version $versions
    Write-Host "Instalando XAMPP versión $selectedVersion..."
    $xamppInstaller = "https://sourceforge.net/projects/xampp/files/XAMPP%20Windows/$selectedVersion/xampp-windows-x64-$selectedVersion.exe/download"
    $installPath = "C:\xampp$selectedVersion"

    Write-Host "Descargando XAMPP desde $xamppInstaller..."
    Invoke-WebRequest -Uri $xamppInstaller -OutFile "$env:TEMP\xampp$selectedVersion.exe"

    Write-Host "Ejecutando el instalador de XAMPP..."
    Start-Process -FilePath "$env:TEMP\xampp$selectedVersion.exe" -ArgumentList "/S /D=$installPath" -Wait

    Write-Host " XAMPP instalado correctamente en $installPath."
}

# Función para obtener versiones de Nginx ordenadas de más nueva a más vieja
function Get-NginxVersions {
    Write-Host "Obteniendo versiones de Nginx..."
    $url = "https://nginx.org/en/download.html"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $matches = [regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+).zip") | ForEach-Object { $_.Groups[1].Value }
    $versions = $matches | Sort-Object { [version]$_ } -Descending
    return $versions
}

# Función para instalar Nginx
function Install-Nginx {
    $versions = Get-NginxVersions
    if ($versions.Count -eq 0) {
        Write-Host " No se encontraron versiones de Nginx disponibles. Abortando..."
        exit
    }

    $selectedVersion = Select-Version $versions
    $port = Select-Port

    Write-Host "Instalando Nginx versión $selectedVersion en el puerto $port..."
    $nginxInstaller = "https://nginx.org/download/nginx-$selectedVersion.zip"
    $installPath = "C:\Nginx$selectedVersion"

    Write-Host "Descargando Nginx desde $nginxInstaller..."
    Invoke-WebRequest -Uri $nginxInstaller -OutFile "$env:TEMP\Nginx$selectedVersion.zip"

    Write-Host "Instalando Nginx en $installPath..."
    Expand-Archive -Path "$env:TEMP\Nginx$selectedVersion.zip" -DestinationPath $installPath -Force

    Write-Host "Configurando Firewall para permitir el puerto $port..."
    New-NetFirewallRule -DisplayName "Nginx Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port

    Write-Host " Nginx instalado en el puerto $port."
}

# Función para seleccionar una versión de un servicio
function Select-Version {
    param ($versions)
    Write-Host "Seleccione una versión:"
    for ($i = 0; $i -lt $versions.Count; $i++) {
        Write-Host "$($i+1). $($versions[$i])"
    }
    do {
        $choice = Read-Host "Ingrese el número de la versión"
        $valid = ($choice -match '^\d+$') -and ($choice -ge 1) -and ($choice -le $versions.Count)
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)
    return $versions[$choice - 1]
}

# Función para seleccionar un puerto
function Select-Port {
    do {
        $port = Read-Host "Ingrese el puerto en el que desea configurar el servicio"
        $valid = ($port -match '^\d+$') -and ($port -ge 1) -and ($port -le 65535)
        if (-not $valid) {
            Write-Host "El puerto debe ser un número entre 1 y 65535. Intente de nuevo."
        }
    } while (-not $valid)
    return $port
}

# Menú de selección con opción de salir
do {
    Write-Host "`n¿Qué desea instalar?"
    Write-Host "1. Instalar IIS (Seleccionar versión)"
    Write-Host "2. Instalar XAMPP (Seleccionar versión)"
    Write-Host "3. Instalar Nginx (Seleccionar versión y puerto)"
    Write-Host "4. Salir"

    do {
        $option = Read-Host "Seleccione una opción (1-4)"
        $valid = $option -match '^[1-4]$'
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)

    switch ($option) {
        "1" { Install-IIS }
        "2" { Install-XAMPP }
        "3" { Install-Nginx }
        "4" { Write-Host "Saliendo del script. ¡Hasta luego!"; exit }
    }
} while ($true)
