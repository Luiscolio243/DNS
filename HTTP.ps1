
function Get-IISVersions {
    Write-Host "`n🔹 Versiones de IIS en Windows Server disponibles:"
    Write-Host "1. IIS 10.0 (Windows Server 2016, 2019, 2022)"
    Write-Host "2. IIS 8.5  (Windows Server 2012 R2)"
    Write-Host "3. IIS 8.0  (Windows Server 2012)"
    Write-Host "4. IIS 7.5  (Windows Server 2008 R2)"
}

# Función para obtener la versión instalada de IIS
function Get-IISVersion {
    if (Get-Command "Get-WindowsFeature" -ErrorAction SilentlyContinue) {
        $iisFeature = Get-WindowsFeature -Name Web-Server
        if ($iisFeature.Installed) {
            $version = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\InetStp").VersionString
            Write-Host "IIS instalado en versión: $version"
        } else {
            Write-Host "IIS no está instalado en el sistema."
        }
    } else {
        Write-Host "⚠ No se pudo obtener información de IIS. Ejecute PowerShell como Administrador."
    }
}

# Función para instalar IIS
function Install-IIS {
    Write-Host "Instalando IIS..."
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Write-Host "IIS instalado correctamente."
    Get-IISVersion  # Mostrar versión después de la instalación
}

# Función para instalar WSL con Ubuntu o Debian
function Install-WSL {
    Write-Host "Instalando Windows Subsystem for Linux (WSL)..."

    # Habilitar características de Windows necesarias para WSL
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /norestart

    Write-Host "Seleccione la distribución de Linux a instalar:"
    Write-Host "1. Ubuntu"
    Write-Host "2. Debian"

    do {
        $choice = Read-Host "Ingrese el número de la distribución"
        $valid = $choice -match '^[1-2]$'
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)

    $distro = if ($choice -eq "1") { "Ubuntu" } else { "Debian" }

    Write-Host "Descargando e instalando $distro..."
    Invoke-WebRequest -Uri "https://aka.ms/wsl-$distro" -OutFile "$env:TEMP\$distro.appx"
    Add-AppxPackage -Path "$env:TEMP\$distro.appx"

    Write-Host "WSL instalado correctamente con $distro. Puede ejecutarlo con el comando `wsl`."
}

# Función para obtener versiones de Nginx desde la página oficial
function Get-NginxVersions {
    Write-Host "Obteniendo versiones de Nginx..."
    $url = "https://nginx.org/en/download.html"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $matches = [regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+).zip") | ForEach-Object { $_.Groups[1].Value }
    $versions = $matches | Sort-Object { [version]$_ }
    return $versions
}

# Función para instalar Nginx
function Install-Nginx {
    param ($version, $port)
    Write-Host "Instalando Nginx versión $version en el puerto $port..."
    $nginxInstaller = "https://nginx.org/download/nginx-$version.zip"
    $installPath = "C:\Nginx$version"

    Write-Host "Descargando Nginx desde $nginxInstaller..."
    Invoke-WebRequest -Uri $nginxInstaller -OutFile "$env:TEMP\Nginx$version.zip"

    Write-Host "Instalando Nginx en $installPath..."
    Expand-Archive -Path "$env:TEMP\Nginx$version.zip" -DestinationPath $installPath -Force

    Write-Host "Configurando Firewall para permitir el puerto $port..."
    New-NetFirewallRule -DisplayName "Nginx Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port

    Write-Host "Nginx instalado en el puerto $port."
}

# Función para seleccionar versión de Nginx
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

# Función para seleccionar puerto
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
    Write-Host "1. Ver versiones de IIS"
    Write-Host "2. Instalar IIS"
    Write-Host "3. Instalar Windows Subsystem for Linux (WSL)"
    Write-Host "4. Instalar Nginx"
    Write-Host "5. Salir"

    do {
        $option = Read-Host "Seleccione una opción (1-5)"
        $valid = $option -match '^[1-5]$'
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)

    switch ($option) {
        "1" {
            Get-IISVersions
        }
        "2" {
            Install-IIS
        }
        "3" {
            Install-WSL
        }
        "4" {
            $versions = Get-NginxVersions
            if ($versions.Count -eq 0) {
                Write-Host "No se encontraron versiones de Nginx disponibles. Abortando..."
                exit
            }
            $selectedVersion = Select-Version $versions
            $port = Select-Port
            Install-Nginx -version $selectedVersion -port $port
        }
        "5" {
            Write-Host "Saliendo del script. ¡Hasta luego!"
            exit
        }
    }
} while ($true)
