function solicitar_puerto {
    param ([string]$msg)

    $ports_restricted = @(1433, 1434, 1521, 3306, 3389,
                          1, 7, 9, 11, 13, 15, 17, 19, 137, 138, 139, 2049, 3128, 5432, 6000, 6379, 6660, 6661, 6662, 6663, 6664, 6665, 6666, 6667, 6668, 6669, 27017, 8000, 8888, 21, 22, 25, 53, 110, 143, 161, 162, 389, 443, 465, 993, 995)

    while ($true) {
        $port = Read-Host $msg

        if ([string]::IsNullOrEmpty($port)){
            return
        }
        # Verificar si el usuario ingresó un número válido
        if ($port -match '^\d+$') {
            $port = [int]$port

            # Validar rango permitido
            if ($port -lt 1 -or $port -gt 65535) {
                Write-Host "El puerto debe estar entre 1 y 65535." -ForegroundColor Red
                continue
            }

            # Verificar si el puerto está en uso
            if (netstat -an | Select-String ":$port " | Where-Object { $_ -match "LISTENING" }) {
                Write-Host "El puerto $port ya está en uso" -ForegroundColor Yellow
                continue
            }

            # Verificar si el puerto está en la lista de restringidos
            if ($port -in $ports_restricted){
                Write-Host "El puerto $port está restringido" -ForegroundColor Yellow
                continue
            }

            # Si pasa todas las validaciones, devolver el puerto
            return $port
        } else {
            Write-Host "Ingresa un número válido." -ForegroundColor Red
        }
    }
}

function conf_IIS {
    param( [string]$port )
    
    Write-Host "Configurando IIS... " -ForegroundColor Green

    # Instalar IIS si no está instalado
    if (-not (Get-WindowsFeature -Name Web-Server).Installed) {
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    }

    # Habilitar el puerto en el firewall
    New-NetFirewallRule -DisplayName "IIS Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port -ErrorAction SilentlyContinue

    # Importar módulo de administración de IIS
    Import-Module WebAdministration

    # Remover el binding HTTP existente en el puerto 80
    Remove-WebBinding -Name "Default Web Site" -Protocol "http" -Port 80 -ErrorAction SilentlyContinue

    # Agregar un nuevo binding con el puerto seleccionado
    New-WebBinding -Name "Default Web Site" -Protocol "http" -Port $port -IPAddress "*"

    # Reiniciar IIS para aplicar los cambios
    iisreset
}

function dependencias{
    # Verificar e instalar Visual C++ Redistributable
    Write-Host "`nVerificando Visual C++ Redistributable..."

    $vcInstalled = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
                Get-ItemProperty | 
                Where-Object { $_.DisplayName -match "Visual C\+\+ (2015|2017|2019|2022) Redistributable" }

    if ($vcInstalled) {
        Write-Host "Visual C++ Redistributable ya está instalado."
    } else {
        Write-Host "Falta Visual C++. Descargando e instalando..."
        $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        $vcInstaller = "$env:TEMP\vc_redist.x64.exe"
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcInstaller
        Start-Process -FilePath $vcInstaller -ArgumentList "/install /quiet /norestart" -NoNewWindow -Wait
        Write-Host "Visual C++ Redistributable instalado correctamente."
    }
}

function menu_http{
    Write-Host "= HTTP ="
    Write-Host "1) IIS"
    Write-Host "2) Apache"
    Write-Host "3) Nginx"
    Write-Host "4) Salir"
}

function menu_http2{
    param (
        [string]$service,
        [string]$stable,
        [string]$mainline
    )
    Write-Host " $service "

    Write-Host "1. Version estable: $stable"
    Write-Host "2. Version de desarrollo: $mainline"
    Write-Host "3. Salir"
}

function obtener_apache {
    $pagina_descarga = Invoke-WebRequest -Uri "https://httpd.apache.org/download.cgi" -UseBasicParsing
    $versiones = [regex]::Matches($pagina_descarga.Content, "httpd-(\d+\.\d+\.\d+)") | ForEach-Object { $_.Groups[1].Value }

    #Verificar si se encontraron versiones
    if (-not $versiones) {
        Write-Host "ERROR: No se encontraron versiones disponibles en la página."
        return
    }

    #Ordenar versiones de menor a mayor
    $versiones_ordenadas = $versiones | Sort-Object { [System.Version]$_ }

    #Obtener la última versión estable (la más reciente)
    $ver_lts = $versiones_ordenadas[-1]

    #Obtener la última versión de desarrollo (si existe)
    $ver_dev = ($versiones_ordenadas | Where-Object { $_ -ne $ver_lts } | Select-Object -Last 1)

    #Validar si la versión de desarrollo es válida
    if (-not $ver_dev -or $ver_dev -match "^\d+\.[0-3]\.") {
        $ver_dev = "No hay version de desarrollo disponible"
    }

    #Mostrar los resultados
    Write-Host "1. Version LTS: $ver_lts"
    Write-Host "2. Version De Desarrollo: $ver_dev "

    #Retornar la version LTS
    return $ver_lts
}

function conf_apache {
    param( 
        [string]$port,
        [string]$version
    )

    # Definir la URL de descarga de Apache con la versión especificada
    $url = "https://www.apachelounge.com/download/VS17/binaries/httpd-$version-250207-win64-VS17.zip"
    $dZip = "$env:USERPROFILE\Downloads\apache-$version.zip"
    $extdestino = "C:\Apache24"

     try {
        Write-Host "Iniciando instalación de Apache HTTP Server versión $version..." -ForegroundColor Green

         # Descargar Apache desde la URL especificada
        Write-Host "Descargando Apache desde: $url"
        $agente = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

        # Sobrescribir la política de certificados SSL para evitar problemas con certificados no confiables
        add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        # Descargar el archivo ZIP de Apache
        Invoke-WebRequest -Uri $url -OutFile $dZip -MaximumRedirection 10 -UserAgent $agente -UseBasicParsing
        #Write-Host "Apache descargado en: $dZip"

        # Extraer el contenido del ZIP en la carpeta de destino
        Expand-Archive -Path $dZip -DestinationPath "C:\" -Force
        Remove-Item -Path $dZip -Force   # Eliminar el archivo ZIP después de extraerlo
        
         # Configurar el puerto en el archivo de configuración httpd.conf
        $configFile = Join-Path $extdestino "conf\httpd.conf"
        if (Test-Path $configFile) {
            (Get-Content $configFile) -replace "Listen 80", "Listen $port" | Set-Content $configFile
            Write-Host "Configuración actualizada para escuchar en el puerto $port" -ForegroundColor Green
        } else {
            Write-Host "Error: No se encontró el archivo de configuración en $configFile"
            return
        }

         # Buscar el ejecutable de Apache dentro de la carpeta extraída
        $apacheExe = Get-ChildItem -Path $extdestino -Recurse -Filter httpd.exe -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($apacheExe) {
            $exeApache = $apacheExe.FullName
            #Write-Host "Instalando Apache como servicio..." -ForegroundColor Green
            # Instalar Apache como un servicio de Windows
            Start-Process -FilePath $exeApache -ArgumentList '-k', 'install', '-n', 'Apache24' -NoNewWindow -Wait
            Write-Host "Iniciando Apache..." -ForegroundColor Green
            Start-Service -Name "Apache24"
            Write-Host "Apache instalado y ejecutándose correctamente en el puerto $port" -ForegroundColor Green

            # Habilitar el puerto en el firewall al final de la instalación
            New-NetFirewallRule -DisplayName "Abrir Puerto $port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow
        } else {
            Write-Host "Error: No se encontró el ejecutable httpd.exe en $extdestino"
        }
    } catch {
        Write-Host "Error durante la instalación de Apache: $_"
    }

}

function obtener_nginx {
    $html = Invoke-WebRequest -Uri "https://nginx.org/en/download.html" -UseBasicParsing
    $versions = [regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+)") | ForEach-Object { $_.Groups[1].Value }

    # Verificar si se encontraron versiones
    if (-not $versions) {
        Write-Host "ERROR: No se encontraron versiones de NGINX disponibles en la página."
        return $null
    }

    # Ordenar versiones de menor a mayor y eliminar duplicados
    $versions = $versions | Sort-Object { [System.Version]$_ } -Unique

    # Última versión de desarrollo 
    $mainline = $versions[-1]

    # Última versión estable
    $stable = $versions | Where-Object { $_ -ne $mainline } | Select-Object -Last 1

    # Validar si mainline existe, si no, asignar "No disponible"
    if (-not $mainline) {
        $mainline = "No disponible"
    }

    # Retornar ambas versiones como objeto
    return [PSCustomObject]@{
        stable   = $stable
        mainline = $mainline
    }
}

function conf_nginx{
    param( 
        [string]$port,
        [string]$version
    )

    $nginxPath = "C:\nginx"
    $nginxConfPath = "$nginxPath\conf\nginx.conf"
    
    #Descargar Nginx (Archivo comprimido)
    $url = "http://nginx.org/download/nginx-$version.zip"
    $zipPath = "$env:TEMP\nginx.zip"
    Write-Host "Descargando Nginx desde $url..."
            # Sobrescribir la política de certificados SSL para evitar problemas con certificados no confiables
        add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    #Descomprimir el archivo
    Expand-Archive -Path $zipPath -DestinationPath "C:\"
    
    #Renombra la carpeta extraída a nginx
    Rename-Item -Path "C:\nginx-$version" -NewName "nginx"
    
    #Configurar el puerto
    (Get-Content $nginxConfPath) -replace "listen       80;", "listen       $port;" | Set-Content $nginxConfPath
    
    #Reemplazar las rutas de los logs en la configuración
    (Get-Content $nginxConfPath) -replace "#error_log\s+logs/error.log;", "error_log C:/nginx/logs/error.log;" | Set-Content $nginxConfPath
    (Get-Content $nginxConfPath) -replace "#pid\s+logs/nginx.pid;", "pid C:/nginx/logs/nginx.pid;" | Set-Content $nginxConfPath
    
    #Iniciamos el servicio
    Start-Process -FilePath "C:\nginx\nginx.exe" -WorkingDirectory "C:\nginx"
    #Verificar si el proceso esta corriendo
    Get-Process -Name nginx
    #Habilitar el puerto en el fireall
    New-NetFirewallRule -DisplayName "Nginx $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
}

Export-ModuleMember -Function solicitar_puerto, conf_IIS, menu_http, menu_http2, obtener_apache, conf_apache, obtener_nginx, conf_nginx
