# Función para verificar si un puerto está disponible
function Is-PortAvailable {
    param (
        [int]$port
    )
    $usedPorts = (Get-NetTCPConnection -State Listen).LocalPort
    return -not ($usedPorts -contains $port)
}

# Función para seleccionar un puerto disponible
function Select-Port {
    do {
        $port = Read-Host "Ingrese el puerto en el que desea instalar el servidor"
        if ($port -match '^[0-9]+$') {
            $port = [int]$port
            if (Is-PortAvailable -port $port) {
                return $port
            } else {
                Write-Host "El puerto $port ya está en uso. Intente con otro puerto." -ForegroundColor Red
            }
        } else {
            Write-Host "Entrada inválida. Ingrese un número de puerto válido." -ForegroundColor Red
        }
    } while ($true)
}

# Función para instalar IIS
function Install-IIS {
    Write-Host "Obteniendo versiones de IIS..."
    $versions = @("IIS 10.0 - Última versión estable", "IIS Insider Preview - Versión en desarrollo")
    
    for ($i = 0; $i -lt $versions.Count; $i++) {
        Write-Host "$($i+1). $($versions[$i])"
    }
    
    do {
        $choice = Read-Host "Seleccione la versión de IIS para instalar (1-2)"
    } while ($choice -notmatch '^[1-2]$')
    
    $selectedVersion = $versions[$choice - 1]
    $port = Select-Port
    
    if (Is-PortAvailable -port $port) {
        Write-Host "Instalando $selectedVersion en el puerto $port..."
        Install-WindowsFeature -name Web-Server -IncludeManagementTools
        New-NetFirewallRule -DisplayName "IIS Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
        Write-Host "Instalación completada para $selectedVersion en el puerto $port."
    } else {
        Write-Host "Error: El puerto $port ya está en uso. No se instalará IIS." -ForegroundColor Red
    }
}

# Función para instalar Apache Tomcat
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
    
    if (Is-PortAvailable -port $port) {
        Write-Host "Instalando Apache Tomcat versión $latestVersion en el puerto $port..."
        New-NetFirewallRule -DisplayName "Tomcat Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
        Write-Host "Tomcat $latestVersion instalado correctamente en el puerto $port."
    } else {
        Write-Host "Error: El puerto $port ya está en uso. No se instalará Tomcat." -ForegroundColor Red
    }
}

# Función para instalar Nginx
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
    } while ($choice -notmatch '^[1-2]$')
    
    $selectedVersion = if ($choice -eq 1) { "nginx-$latestVersion" } else { $devVersion }
    $port = Select-Port
    
    if (Is-PortAvailable -port $port) {
        Write-Host "Instalando $selectedVersion en el puerto $port..."
        New-NetFirewallRule -DisplayName "Nginx Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
        Write-Host "$selectedVersion instalado en el puerto $port."
    } else {
        Write-Host "Error: El puerto $port ya está en uso. No se instalará Nginx." -ForegroundColor Red
    }
}

# Menú de selección
Do {
    Write-Host "`n¿Qué desea instalar?"
    Write-Host "1. Instalar IIS"
    Write-Host "2. Instalar Apache Tomcat"
    Write-Host "3. Instalar Nginx"
    Write-Host "4. Salir"
    
    do {
        $option = Read-Host "Seleccione una opción (1-4)"
    } while ($option -notmatch '^[1-4]$')
    
    switch ($option) {
        "1" { Install-IIS }
        "2" { Install-Tomcat }
        "3" { Install-Nginx }
        "4" { Write-Host "Saliendo del script. ¡Hasta luego!"; exit }
    }
} while ($true)