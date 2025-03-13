#HTTP   

Import-Module "C:\Users\Administrador\Desktop\validacionesWindows\modulohttp.psm1"

# Verifica si el script se está ejecutando como Administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Este script debe ejecutarse como Administrador." -ForegroundColor Red
    exit
}

while ($true) {
    menu_http
    $op = Read-Host "Seleccione el servicio HTTP que queria instalar y configurar: "

    switch ($op) {
        "1" {
            $port = solicitar_puerto "Ingresa el puerto para el servicio IIS:"
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
                Write-Host "Regresando..." -ForegroundColor Yellow
            }
        }
        "3" {
            $version= obtener_nginx
            menu_http2 "Nginx" $version.stable $version.mainline
            $op2 = Read-Host "Seleccione una opcion:"
            if ($op2 -eq "1"){
                $port = solicitar_puerto "Ingresa el puerto:"
                if ([string]::IsNullOrEmpty($port)){
                    continue
                }
                conf_nginx -port $port -version $version.stable
            } elseif ($op2 -eq "2"){
                $port = solicitar_puerto "Ingresa el puerto:"
                if ([string]::IsNullOrEmpty($port)){
                    continue
                }
                conf_nginx -port $port -version $version.mainline
            } elseif ($op2 -eq "3"){
                Write-Host "Regresando..." -ForegroundColor Yellow
            } else {
                Write-Host "Opcion no valida. Regresando al menu..." -ForegroundColor Yellow
            }
        }
        "4" {
            exit
        }
        default {
            Write-Host "Opcion no valida." -ForegroundColor Red
        }
    }


}