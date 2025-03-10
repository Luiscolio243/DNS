

function Get-ApacheVersions {
    Write-Host "Obteniendo versiones de Apache..."
    $url = "https://downloads.apache.org/httpd/"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $versions = $html.Links | Where-Object { $_.href -match 'httpd-(\d+\.\d+\.\d+)/' } | ForEach-Object { $_.href -replace 'httpd-|/', '' }
    $versions = $versions | Sort-Object { [version]$_ }
    return $versions
}

function Get-NginxVersions {
    Write-Host "Obteniendo versiones de Nginx..."
    $url = "https://nginx.org/en/download.html"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $matches = [regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+).zip") | ForEach-Object { $_.Groups[1].Value }
    $versions = $matches | Sort-Object { [version]$_ }
    return $versions
}

function Install-IIS {
    Write-Host "Instalando IIS..."
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Write-Host "IIS instalado correctamente en el puerto 80."
}

function Install-Apache {
    param ($version, $port)
    Write-Host "Instalando Apache versión $version en el puerto $port..."
    $apacheInstaller = "https://downloads.apache.org/httpd/httpd-$version-win64-VS16.zip"
    $installPath = "C:\Apache$version"

    Write-Host "Descargando Apache desde $apacheInstaller..."
    Invoke-WebRequest -Uri $apacheInstaller -OutFile "$env:TEMP\Apache$version.zip"

    Write-Host "Instalando Apache en $installPath..."
    Expand-Archive -Path "$env:TEMP\Apache$version.zip" -DestinationPath $installPath -Force

    Write-Host "Configurando Firewall para permitir el puerto $port..."
    New-NetFirewallRule -DisplayName "Apache Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
}

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
}

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

function Verify-Service {
    param ($port)
    Write-Host "`nVerificando si el servicio está activo en el puerto $port..."
    $output = netstat -ano | Select-String ":$port"
    if ($output) {
        Write-Host " Servicio corriendo en el puerto $port."
    } else {
        Write-Host " No se detectó ningún servicio en el puerto $port."
    }
}

do {
    Write-Host "`n¿Qué servicio desea instalar?"
    Write-Host "1. IIS (Internet Information Services)"
    Write-Host "2. Apache"
    Write-Host "3. Nginx"
    Write-Host "4. Salir"

    do {
        $option = Read-Host "Seleccione una opción (1-4)"
        $valid = $option -match '^[1-4]$'
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)

    switch ($option) {
        "1" {
            Install-IIS
        }
        "2" {
            $versions = Get-ApacheVersions
            if ($versions.Count -eq 0) {
                Write-Host "No se encontraron versiones de Apache disponibles. Abortando..."
                exit
            }
            $selectedVersion = Select-Version $versions
            $port = Select-Port
            Install-Apache -version $selectedVersion -port $port
            Verify-Service -port $port
        }
        "3" {
            $versions = Get-NginxVersions
            if ($versions.Count -eq 0) {
                Write-Host "No se encontraron versiones de Nginx disponibles. Abortando..."
                exit
            }
            $selectedVersion = Select-Version $versions
            $port = Select-Port
            Install-Nginx -version $selectedVersion -port $port
            Verify-Service -port $port
        }
        "4" {
            Write-Host "Saliendo del script. ¡Hasta luego!"
            exit
        }
    }

    Write-Host "`nInstalación finalizada con éxito."

    do {
        $continue = Read-Host "¿Desea instalar otro servicio? (s/n)"
        $validContinue = $continue -match '^[sSnN]$'
        if (-not $validContinue) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $validContinue)

} while ($continue -match '^[sS]$')

Write-Host "Saliendo del script. ¡Hasta luego!"
exit
