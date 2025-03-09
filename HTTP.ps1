# Script para instalar Apache, Tomcat o Nginx en Windows Server

function Elegir-Version {
    param (
        [string]$Servicio,
        [string]$Url
    )
    
    Write-Host "Obteniendo versiones disponibles de $Servicio..."
    $Versiones = (Invoke-WebRequest -Uri $Url -UseBasicParsing).Links | Where-Object { $_.href -match '\d+\.\d+\.\d+/' } | ForEach-Object { $_.href -replace '/$','' }
    
    if (-not $Versiones) {
        Write-Host "No se encontraron versiones disponibles para $Servicio."
        exit 1
    }
    
    Write-Host "Seleccione la versión de $Servicio:"
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

# Función para instalar Apache
function Instalar-Apache {
    $Version = Elegir-Version "Apache" "https://downloads.apache.org/httpd/"
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Apache"
    
    Write-Host "Descargando Apache versión $Version..."
    Invoke-WebRequest -Uri "https://downloads.apache.org/httpd/httpd-$Version-win64.zip" -OutFile "$env:TEMP\Apache.zip"
    Expand-Archive -Path "$env:TEMP\Apache.zip" -DestinationPath "C:\Apache"
    
    (Get-Content "C:\Apache\conf\httpd.conf") -replace 'Listen 80', "Listen $Puerto" | Set-Content "C:\Apache\conf\httpd.conf"
    Start-Process -FilePath "C:\Apache\bin\httpd.exe" -ArgumentList "-k install" -NoNewWindow -Wait
    net start Apache2.4
    Write-Host "Apache instalado y configurado en el puerto $Puerto."
}

# Función para instalar Tomcat
function Instalar-Tomcat {
    $Version = Elegir-Version "Tomcat" "https://downloads.apache.org/tomcat/"
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Tomcat"
    
    Write-Host "Descargando Tomcat versión $Version..."
    Invoke-WebRequest -Uri "https://downloads.apache.org/tomcat/tomcat-$Version-windows.zip" -OutFile "$env:TEMP\Tomcat.zip"
    Expand-Archive -Path "$env:TEMP\Tomcat.zip" -DestinationPath "C:\Tomcat"
    
    (Get-Content "C:\Tomcat\conf\server.xml") -replace 'port="8080"', "port="$Puerto"" | Set-Content "C:\Tomcat\conf\server.xml"
    Start-Process -FilePath "C:\Tomcat\bin\catalina.bat" -ArgumentList "run" -NoNewWindow -Wait
    Write-Host "Tomcat instalado y configurado en el puerto $Puerto."
}

# Función para instalar Nginx
function Instalar-Nginx {
    $Version = Elegir-Version "Nginx" "http://nginx.org/download/"
    $Puerto = Read-Host "Ingrese el puerto en el que desea configurar Nginx"
    
    Write-Host "Descargando Nginx versión $Version..."
    Invoke-WebRequest -Uri "http://nginx.org/download/nginx-$Version.zip" -OutFile "$env:TEMP\Nginx.zip"
    Expand-Archive -Path "$env:TEMP\Nginx.zip" -DestinationPath "C:\Nginx"
    
    (Get-Content "C:\Nginx\conf\nginx.conf") -replace 'listen 80;', "listen $Puerto;" | Set-Content "C:\Nginx\conf\nginx.conf"
    Start-Process -FilePath "C:\Nginx\nginx.exe" -NoNewWindow -Wait
    Write-Host "Nginx instalado y configurado en el puerto $Puerto."
}

# Menú de selección de servicio
Write-Host "¿Qué servicio desea instalar?"
Write-Host "1.- Apache"
Write-Host "2.- Tomcat"
Write-Host "3.- Nginx"
Write-Host "4.- Salir"
$choice = Read-Host "Seleccione una opción (1-4)"

switch ($choice) {
    "1" { Instalar-Apache }
    "2" { Instalar-Tomcat }
    "3" { Instalar-Nginx }
    "4" { Write-Host "Saliendo..."; exit 0 }
    default { Write-Host "Opción inválida. Saliendo..."; exit 1 }
}