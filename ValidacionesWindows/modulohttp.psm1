function obtenerPuerto {
    param ([string]$mensaje)

    $puertosRestringidos = @(1433, 1434, 1521, 3306, 3389, 
                              1, 7, 9, 11, 13, 15, 17, 19, 137, 138, 139, 2049, 3128, 5432, 6000, 6379, 
                              6660, 6661, 6662, 6663, 6664, 6665, 6666, 6667, 6668, 6669, 27017, 8000, 8080, 8888)

    do {
        $puerto = Read-Host $mensaje

        if ([string]::IsNullOrEmpty($puerto)) {
            return
        }

        if ($puerto -match '^\d+$') {
            $puerto = [int]$puerto

            if ($puerto -lt 1 -or $puerto -gt 65535) {
                Write-Output "El puerto debe estar entre 1 y 65535."
                continue
            }

            if (Get-NetTCPConnection -LocalPort $puerto -ErrorAction SilentlyContinue) {
                Write-Output "El puerto $puerto ya está en uso. Prueba con otro."
                continue
            }

            if ($puerto -in $puertosRestringidos) {
                Write-Output "El puerto $puerto está restringido. Intenta otro."
                continue
            }

            return $puerto
        } else {
            Write-Output "Ingresa un número válido."
        }
    } while ($true)
}

function configurarIIS {
    param ([string]$puerto)

    Write-Output "Configurando IIS..."

    if (-not (Get-WindowsFeature -Name Web-Server).Installed) {
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    }

    New-NetFirewallRule -DisplayName "IIS Puerto $puerto" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $puerto -ErrorAction SilentlyContinue

    Import-Module WebAdministration

    Remove-WebBinding -Name "Default Web Site" -Protocol "http" -Port 80 -ErrorAction SilentlyContinue
    New-WebBinding -Name "Default Web Site" -Protocol "http" -Port $puerto -IPAddress "*"

    iisreset
}

function verificarDependencias {
    Write-Output "Verificando Visual C++ Redistributable..."

    $vc_instalado = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
        Get-ItemProperty | 
        Where-Object { $_.DisplayName -match "Visual C\+\+ (2015|2017|2019|2022) Redistributable" }

    if ($vc_instalado) {
        Write-Output "Visual C++ Redistributable ya está instalado."
    } else {
        Write-Output "No encontrado. Descargando e instalando..."
        $url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        $installer = "$env:TEMP\vc_redist.x64.exe"
        Invoke-RestMethod -Uri $url -OutFile $installer
        Start-Process -FilePath $installer -ArgumentList "/install /quiet /norestart" -NoNewWindow -Wait
        Write-Output "Instalación completada."
    }
}

function mostrarMenuHTTP {
    Write-Output "--- Menú Servicios HTTP ---"
    Write-Output "1) IIS"
    Write-Output "2) Apache"
    Write-Output "3) Nginx"
    Write-Output "4) Salir"
}

function mostrarMenuHTTP2 {
    param (
        [string]$servicio,
        [string]$lts,
        [string]$dev
    )
    Write-Output "--- $servicio ---"
    Write-Output "1. Versión LTS: $lts"
    Write-Output "2. Versión de desarrollo: $dev"
    Write-Output "3. Salir"
}

function descargarApache {
    $html = Invoke-RestMethod -Uri "https://httpd.apache.org/download.cgi" -UseBasicParsing
    $versiones = [regex]::Matches($html.Content, "httpd-(\d+\.\d+\.\d+)") | ForEach-Object { $_.Groups[1].Value }

    if (-not $versiones) {
        Write-Output "No se encontraron versiones disponibles."
        return
    }

    $ordenadas = $versiones | Sort-Object { [System.Version]$_ }
    $lts = $ordenadas[-1]
    $dev = ($ordenadas | Where-Object { $_ -ne $lts } | Select-Object -Last 1) -or "No disponible"

    Write-Output "1. Versión LTS: $lts"
    Write-Output "2. Versión de Desarrollo: $dev"
    
    return $lts
}

function configurarApache {
    param ([string]$puerto, [string]$version)

    $url = "https://www.apachelounge.com/download/VS17/binaries/httpd-$version-250207-win64-VS17.zip"
    $zipPath = "$env:USERPROFILE\Downloads\apache-$version.zip"
    $destino = "C:\Apache24"

    Write-Output "Descargando Apache versión $version..."
    Invoke-RestMethod -Uri $url -OutFile $zipPath

    Expand-Archive -Path $zipPath -DestinationPath "C:\" -Force
    Remove-Item -Path $zipPath -Force

    $configFile = "$destino\conf\httpd.conf"
    (Get-Content $configFile) -replace "Listen 80", "Listen $puerto" | Set-Content $configFile

    Start-Process -FilePath "$destino\bin\httpd.exe" -ArgumentList '-k', 'install', '-n', 'Apache24' -NoNewWindow -Wait
    Start-Service -Name "Apache24"
    
    New-NetFirewallRule -DisplayName "Apache $puerto" -Direction Inbound -Protocol TCP -LocalPort $puerto -Action Allow
    Write-Output "Apache configurado en el puerto $puerto."
}

function descargarNginx {
    $html = Invoke-RestMethod -Uri "https://nginx.org/en/download.html" -UseBasicParsing
    $versiones = [regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+)") | ForEach-Object { $_.Groups[1].Value }

    if (-not $versiones) {
        Write-Output "No se encontraron versiones de Nginx disponibles."
        return $null
    }

    $ordenadas = $versiones | Sort-Object { [System.Version]$_ } -Unique
    $mainline = $ordenadas[-1]
    $estable = ($ordenadas | Where-Object { $_ -ne $mainline } | Select-Object -Last 1) -or "No disponible"

    return [PSCustomObject]@{ estable = $estable; mainline = $mainline }
}

function configurarNginx {
    param ([string]$puerto, [string]$version)

    $url = "http://nginx.org/download/nginx-$version.zip"
    $zipPath = "$env:TEMP\nginx.zip"
    
    Write-Output "Descargando Nginx versión $version..."
    Invoke-RestMethod -Uri $url -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath "C:\"

    Rename-Item -Path "C:\nginx-$version" -NewName "C:\nginx"
    (Get-Content "C:\nginx\conf\nginx.conf") -replace "listen       80;", "listen       $puerto;" | Set-Content "C:\nginx\conf\nginx.conf"
    
    Start-Process -FilePath "C:\nginx\nginx.exe" -NoNewWindow -Wait
    New-NetFirewallRule -DisplayName "Nginx $puerto" -Direction Inbound -Protocol TCP -LocalPort $puerto -Action Allow

    Write-Output "Nginx configurado en el puerto $puerto."
}

Export-ModuleMember -Function obtenerPuerto, configurarIIS, verificarDependencias, mostrarMenuHTTP, mostrarMenuHTTP2, descargarApache, configurarApache, descargarNginx, configurarNginx
