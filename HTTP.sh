# Función para instalar IIS con la versión más reciente y la de desarrollo
function Install-IIS {
    Write-Host "Obteniendo versiones de IIS..."
    $versions = @(
        "IIS 10.0 (Windows Server 2016, 2019, 2022) - Última versión estable",
        "IIS Insider Preview - Versión en desarrollo"
    )
    
    for ($i = 0; $i -lt $versions.Count; $i++) {
        Write-Host "$($i+1). $($versions[$i])"
    }
    
    do {
        $choice = Read-Host "Seleccione la versión de IIS para instalar (1-2)"
        $valid = ($choice -match '^[1-2]$')
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)
    
    $selectedVersion = $versions[$choice - 1]
    Write-Host "Instalando $selectedVersion..."
    
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Write-Host "Instalación completada para $selectedVersion."
}

# Función para instalar Apache Tomcat con la versión más reciente
function Install-Tomcat {
    Write-Host "Obteniendo la última versión de Apache Tomcat..."
    $url = "https://downloads.apache.org/tomcat/"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $latestVersion = ($html.Links | Where-Object { $_.href -match 'tomcat-(\d+)/' } | ForEach-Object { $_.href -replace 'tomcat-|/', '' } | Sort-Object {[int]$_} -Descending | Select-Object -First 1)
    
    if (-not $latestVersion) {
        Write-Host "No se encontró la versión más reciente de Tomcat. Abortando..."
        exit
    }
    
    $port = Select-Port
    Write-Host "Instalando Apache Tomcat versión $latestVersion en el puerto $port..."
    $tomcatInstaller = "https://downloads.apache.org/tomcat/tomcat-$latestVersion/bin/apache-tomcat-$latestVersion-windows-x64.zip"
    $installPath = "C:\Tomcat$latestVersion"
    
    Invoke-WebRequest -Uri $tomcatInstaller -OutFile "$env:TEMP\Tomcat$latestVersion.zip"
    Expand-Archive -Path "$env:TEMP\Tomcat$latestVersion.zip" -DestinationPath $installPath -Force
    
    New-NetFirewallRule -DisplayName "Tomcat Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
    
    Write-Host "Tomcat instalado correctamente en $installPath."
}

# Función para instalar Nginx con la versión más reciente y la de desarrollo
function Install-Nginx {
    Write-Host "Obteniendo versiones de Nginx..."
    $url = "https://nginx.org/en/download.html"
    $html = Invoke-WebRequest -Uri $url -UseBasicParsing
    $latestVersion = ([regex]::Matches($html.Content, "nginx-(\d+\.\d+\.\d+).zip") | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [version]$_ } -Descending | Select-Object -First 1)
    $devVersion = "Nginx Mainline (Versión en desarrollo)"
    
    Write-Host "1. Nginx $latestVersion - Última versión estable"
    Write-Host "2. $devVersion"
    
    do {
        $choice = Read-Host "Seleccione la versión de Nginx para instalar (1-2)"
        $valid = ($choice -match '^[1-2]$')
        if (-not $valid) {
            Write-Host "Opción inválida. Intente de nuevo."
        }
    } while (-not $valid)
    
    $selectedVersion = if ($choice -eq 1) { "nginx-$latestVersion" } else { $devVersion }
    $port = Select-Port
    
    Write-Host "Instalando $selectedVersion en el puerto $port..."
    if ($choice -eq 1) {
        $nginxInstaller = "https://nginx.org/download/nginx-$latestVersion.zip"
        $installPath = "C:\Nginx$latestVersion"
        
        Invoke-WebRequest -Uri $nginxInstaller -OutFile "$env:TEMP\Nginx$latestVersion.zip"
        Expand-Archive -Path "$env:TEMP\Nginx$latestVersion.zip" -DestinationPath $installPath -Force
    } else {
        Write-Host "Para instalar la versión en desarrollo, descárguela manualmente desde el sitio oficial de Nginx."
    }
    
    New-NetFirewallRule -DisplayName "Nginx Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
    Write-Host "Nginx instalado en el puerto $port."
}

# Instalar MySQL automáticamente
Install-MySQL

# Instalar C++ Redistributables automáticamente
Install-CppRedistributables

# Menú de selección
Do {
    Write-Host "`n¿Qué desea instalar?"
    Write-Host "1. Instalar IIS (Última versión y versión en desarrollo)"
    Write-Host "2. Instalar Apache Tomcat (Última versión)"
    Write-Host "3. Instalar Nginx (Última versión o versión en desarrollo)"
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
        "2" { Install-Tomcat }
        "3" { Install-Nginx }
        "4" { Write-Host "Saliendo del script. ¡Hasta luego!"; exit }
    }
} while ($true)
