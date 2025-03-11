Import-Module "C:\Users\Administrator\Desktop\practicas\validaciones-ps1\Configurar-IP.psm1"
Import-Module "C:\Users\Administrator\Desktop\practicas\validaciones-ps1\Configurar-FTP.psm1"
Import-Module "C:\Users\Administrator\Desktop\practicas\validaciones-ps1\Crear-Usuario.psm1"
Import-Module "C:\Users\Administrator\Desktop\practicas\validaciones-ps1\Cambiar-Grupo.psm1"

# Definir la IP fija a usar
$ip_address = "192.168.1.11"

# Llamar a las funciones principales
Configurar-IP -ip_address $ip_address
Configurar-FTP

# Menú Interactivo
while ($true) {
    Write-Host "\n=== Menú de Administración FTP ===" -ForegroundColor Cyan
    Write-Host "1. Crear un nuevo usuario FTP"
    Write-Host "2. Cambiar de grupo a un usuario"
    Write-Host "3. Salir"
    
    $opcion = Read-Host "Seleccione una opción (1-3)"
    
    switch ($opcion) {
        "1" { Crear-UsuarioFTP }
        "2" { Cambiar-GrupoFTP }
        "3" {
            Write-Host "Saliendo..." -ForegroundColor Yellow
            exit
        }

        default {
            Write-Host "Opción inválida. Intente de nuevo." -ForegroundColor Red
        }
    }
}