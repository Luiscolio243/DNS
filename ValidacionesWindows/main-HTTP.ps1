#HTTP   

Import-Module "C:\Users\Administrador\Desktop\validacionesWindows\modulohttp.psm1"
Import-Module "C:\Users\Administrador\Desktop\validacionesWindows\moduloFTP-HTTP.psm1"
Import-Module "C:\Users\Administrador\Desktop\validacionesWindows\moduloFTP-Descarga.psm1"

# Verifica si el script se está ejecutando como Administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script debe ejecutarse como Administrador." 
    exit
}

:main_loop
While ($true) {
Write-Host "Seleccione su instalacion"
Write-Host "1. HTTP"
Write-Host "2. FTP"
$opcion = Read-Host "Ingrese su opcion"

if ($opcion -eq "1") {
    while ($true) {
        menu_http
        $op = Read-Host "Seleccione el servicio HTTP que queria instalar y configurar: "
    
        switch ($op) {
            "1" {
                $port = solicitar_puerto "Ingresa el puerto: "
                if ([string]::IsNullOrEmpty($port)){
                    continue
                }
                conf_IIS -port "$port"
            }
            "2" {
                $version= obtener_apache
                $op2 = Read-Host "1 para instalar Apache o cualquier otro para regresar"
                if ($op2 -eq "1") {
                    $port = solicitar_puerto "Ingresa el puerto:"
                    if ([string]::IsNullOrEmpty($port)){
                        continue
                    }
                    conf_apache -port $port -version "$version"
                } else {
                    Write-Host "Regresando" 
                }
            }
            "3" {
                $version = obtener_nginx
    
                do {
                    menu_http2 "Nginx" $version.stable $version.mainline
                    $op2 = Read-Host "Seleccione una opcion (1, 2 o 3):"
        
                if ($op2 -eq "1" -or $op2 -eq "2" -or $op2 -eq "3") {
                    break
                } else {
                    Write-Host "Opción no válida. Inténtalo de nuevo."
                }
                } while ($true)
    
                if ($op2 -eq "1") {
                    $port = solicitar_puerto "Ingresa el puerto:"
                    if (-not [string]::IsNullOrEmpty($port)) {
                    conf_nginx -port $port -version $version.stable
                }
                } elseif ($op2 -eq "2") {
                    $port = solicitar_puerto "Ingresa el puerto:"
                    if (-not [string]::IsNullOrEmpty($port)) {
                    conf_nginx -port $port -version $version.mainline
                    }
                } elseif ($op2 -eq "3") {
                    Write-Host "Regresando"
                }
            }
            "4" {
                continue
            }
            default {
                Write-Host "Opcion no valida." 
            }
        }
    
    
    }
} elseif ($opcion -eq "2") {
    $ftpFolders = Get-FTPList | Where-Object { $_.Trim() -ne "" }
    if ($ftpFolders.Count -eq 0) {
        Write-Host "No se encontraron carpetas en el FTP." -ForegroundColor Red
        continue main_loop
    }

    Write-Host "`n= SERVICIOS EN EL FTP =" 
    for ($i = 0; $i -lt $ftpFolders.Count; $i++) {
        Write-Host "$($i+1). $($ftpFolders[$i].Trim())"
    }
    Write-Host "0. Regresar al menu"
    $seleccion = Read-Host "Seleccione el servicio a instalar (1-$($ftpFolders.Count)) o 0 para salir"
    if ($seleccion -eq "0") {
        #Write-Host "Regresando..."
        continue main_loop
    } elseif ($seleccion -match "^\d+$" -and [int]$seleccion -le $ftpFolders.Count) {
        $carpetaSeleccionada = $ftpFolders[$seleccion - 1].Trim()
        #Write-Host "Selecciono la carpeta: $carpetaSeleccionada"

        $ftpServer = "192.168.1.2"
        $ftpUser = "windows"
        $ftpPass = "1234"

        # Mostrar carpeta seleccionada
        $selectedService = $ftpFolders[[int]$seleccion - 1].Trim()
        Write-Host "Selecciono la carpeta: $selectedService" -ForegroundColor Yellow

        # Verificamos que $selectedService no esté vacío
        if ([string]::IsNullOrWhiteSpace($selectedService)) {
            Write-Host "Error: La carpeta seleccionada es vacia o invalida." -ForegroundColor Red
            continue main_loop
        }

        # Construimos y mostramos la ruta que se va a usar
        $rutaFTP = "$selectedService/"
        #Write-Host "Ruta que se usara en la conexión FTP: $rutaFTP" -ForegroundColor Cyan

        # Llamamos a la función con la ruta correcta
        $files = listar_http -ftpServer $ftpServer -ftpUser $ftpUser -ftpPass $ftpPass -directory $rutaFTP

        # Filtramos y validamos resultados
        $files = $files | Where-Object { ($_ -match '\S') -and ($_ -ne $null) } | ForEach-Object { $_.Trim() }

        if ($files.Count -eq 0) {
            Write-Host "No se encontraron archivos en el directorio." -ForegroundColor Red
            continue main_loop
        }

        if ($files -isnot [System.Array]) {
            $files = @($files)
        }

        # Mostramos las versiones encontradas
        $index = 1
        foreach ($file in $files) {
            # Detecta NGINX
            if ($file -match 'nginx-([0-9]+\.[0-9]+\.[0-9]+)\.zip') {
                $version = $matches[1]
                if ($index -eq 1) {
                    Write-Host "$index. Version estable: $version"
                } elseif ($index -eq 2) {
                    Write-Host "$index. Version de desarrollo: $version"
                } else {
                    Write-Host "$index. $version"
                }
            }
            # Detecta Apache
            elseif ($file -match 'httpd-([0-9]+\.[0-9]+\.[0-9]+)') {
                $version = $matches[1]
                Write-Host "$index. Version estable: $version"
            }
            else {
                Write-Host "$index. $file"
            }
            $index++
        }
        Write-Host "0. Regresar al menu"
        do {
            $op2 = Read-Host "Elija la version que desea instalar (1-$($files.Count)), o escriba 0 para regresar"
            if ($op2 -eq "0") { 
                #Write-Host "Regresando ..." -ForegroundColor Yellow
                continue main_loop
            }
            if ($op2 -match "^\d+$" -and [int]$op2 -le $files.Count) {
                break
            } else {
                Write-Host "Opción no valida. Intente de nuevo" -ForegroundColor Red
            }
        } while ($true)

        # Guardamos la versión seleccionada
        $selectedFile = $files[[int]$op2 - 1]
        #Write-Host "Selecciono la version: $selectedFile" -ForegroundColor Green

        if ($carpetaSeleccionada -eq "Apache") {
            $port = solicitar_puerto "Ingresa el puerto:"
            if ([string]::IsNullOrEmpty($port)) {
                Write-Host "Puerto no ingresado. Regresando al menú..." -ForegroundColor Yellow
                continue
            }

            DescargarYDescomprimir -ftpServer $ftpServer -ftpUser $ftpUser -ftpPass $ftpPass `
                                   -carpetaSeleccionada $carpetaSeleccionada -selectedFile $selectedFile -Port $port

            $rutaApache = "C:\\Apache24"
            Configurar-Apache -RutaDestino $rutaApache -Port $port
        }
        elseif ($carpetaSeleccionada -eq "Nginx") {
            $port = solicitar_puerto "Ingresa el puerto:"
            if ([string]::IsNullOrEmpty($port)) {
                Write-Host "Puerto no ingresado. Regresando al menú..." -ForegroundColor Yellow
                continue
            }
        
            DescargarYDescomprimir -ftpServer $ftpServer -ftpUser $ftpUser -ftpPass $ftpPass `
                                   -carpetaSeleccionada $carpetaSeleccionada -selectedFile $selectedFile -Port $port
        
            # Obtener versión desde el nombre del archivo seleccionado
            if ($selectedFile -match '([0-9]+\.[0-9]+\.[0-9]+)') {
                $versionNginx = $matches[1]
            } else {
                Write-Host "No se pudo detectar la versión de Nginx" -ForegroundColor Red
                continue
            }
        
            $rutaNginx = "C:\Nginx"
            $IP = "192.168.1.11"  # O pedirla al usuario si quieres
        
            Configurar-Nginx -RutaDestino $rutaNginx -Port $port -version $versionNginx -IP $IP
        }

    }
} else {
    Write-Host "Opcion no valida" -ForegroundColor Red
}
}
