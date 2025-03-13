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
    Write-Host "Instalando $selectedVersion..."
    
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Write-Host "Instalación completada para $selectedVersion."
}

# Función para instalar Apache Tomcat
function Install-Tomcat {
    Write-Host "Obteniendo la última versión de Apache Tomcat..."
    $port = Select-Port
    Write-Host "Instalando Apache Tomcat en el puerto $port..."
    # Proceso de instalación aquí
    New-NetFirewallRule -DisplayName "Tomcat Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
    Write-Host "Tomcat instalado correctamente."
}

# Función para instalar Nginx
function Install-Nginx {
    Write-Host "Obteniendo versiones de Nginx..."
    $port = Select-Port
    Write-Host "Instalando Nginx en el puerto $port..."
    # Proceso de instalación aquí
    New-NetFirewallRule -DisplayName "Nginx Port $port" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
    Write-Host "Nginx instalado en el puerto $port."
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
