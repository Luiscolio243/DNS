# Cargar módulos de validación
Import-Module "C:\Users\Administrador\Desktop\validaciones-ps1\Validar-NombreUsuario.psm1"
Import-Module "C:\Users\Administrador\Desktop\validaciones-ps1\Validar-Contrasena.psm1"
Import-Module "C:\Users\Administrador\Desktop\validaciones-ps1\adfunctions2.psm1"
Import-Module "C:\Users\Administrador\Desktop\validaciones-ps1\auditorias_AD.psm1"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

#New-NetIpAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.1.13 -PrefixLength 24 -DefaultGateway 192.168.1.1

function AddUser {
    Param(
        [String]$Username,
        [String]$Password,
        [String]$UO
    )

    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force

    try {
        New-ADUser -Name $Username `
                   -SamAccountName $Username `
                   -UserPrincipalName "$Username@luiscolio.com" `
                   -ChangePasswordAtLogon $false `
                   -AccountPassword $SecurePassword `
                   -Path "OU=$UO,DC=luiscolio,DC=com" `
                   -Enabled $true

        Write-Host "`nUsuario '$Username' agregado correctamente a la OU '$UO'.`n" -ForegroundColor Green
    } catch {
        Write-Host "`nError al agregar el usuario: $_" -ForegroundColor Red
    }
}

# MENÚ PRINCIPAL
do {
    Clear-Host
    Write-Host "===== MENÚ ====="
    Write-Host "1. Agregar usuario"
    Write-Host "2. Salir"
    Write-Host "3. Ver auditorías"
    Write-Host "(Las configuraciones de seguridad se aplicarán al salir con la opción 2)" -ForegroundColor Yellow
    $opcion = Read-Host "Ingrese una opción (1 o 2)"

    switch ($opcion) {
        "1" {
            $nombreValido = $false
            while (-not $nombreValido) {
                $nombre = Validar-NombreUsuario
                if ($nombre) {
                    $nombreValido = $true
                }
            }

            $contrasenaValida = $false
            while (-not $contrasenaValida) {
                $contrasena = Validar-Contrasena $nombre
                if ($contrasena) {
                    $contrasenaValida = $true
                }
            }

            # Preguntar por la UO
            do {
                $uo = Read-Host "Seleccione la unidad organizativa: 1.cuates  2.nocuates"
                switch ($uo) {
                    "1" { $uo = "cuates"; $valido = $true }
                    "2" { $uo = "no cuates"; $valido = $true }
                    default {
                        Write-Host "Opción inválida. Ingrese 1 o 2." -ForegroundColor Red
                        $valido = $false
                    }
                }
            } while (-not $valido)

            AddUser -Username $nombre -Password $contrasena -UO $uo
            Pause
        }
        "2" {
            Write-Host "Saliendo..."
        }
        "3" {
            Get-ADEvents
        }
        default {
            Write-Host "Opción inválida. Intente de nuevo." -ForegroundColor Red
            Pause
        }
    }
} while ($opcion -ne "2")

restriccion_horarios
restriccion_archivos
restriccion_aplicaciones
passwords_seguras
habilitar_auditorias

Write-Host "Configuraciones de seguridad aplicadas correctamente." -ForegroundColor Cyan
Pause