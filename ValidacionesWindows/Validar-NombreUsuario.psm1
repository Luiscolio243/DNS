# Lista de nombres reservados por Windows
$NombresReservados = @("Administrator", "Guest", "System", "LocalService", "NetworkService", "DefaultAccount")

# Función para validar el nombre de usuario
function Validar-NombreUsuario {
    while ($true) {
        $NombreUsuario = Read-Host "Ingrese el nombre del usuario"

        if ($NombreUsuario.Length -lt 1 -or $NombreUsuario.Length -gt 8) {
            Write-Host "Error: El nombre de usuario debe tener entre 1 y 8 caracteres." -ForegroundColor Red
            continue
        }

        # Validar que no tenga espacios en blanco
        if ($NombreUsuario -match "\s") {
            Write-Host "Error: El nombre de usuario no puede contener espacios en blanco." -ForegroundColor Red
            continue
        }

        if ($NombreUsuario -match "[^a-zA-Z0-9]") {
            Write-Host "Error: El nombre de usuario no puede contener caracteres especiales." -ForegroundColor Red
            continue
        }

        if ($NombreUsuario -match "^\d+$") {
            Write-Host "Error: El nombre de usuario no puede ser solo números, debe incluir al menos una letra." -ForegroundColor Red
            continue
        }

        # Validar que no inicie con un número
        if ($NombreUsuario -match "^\d") {
            Write-Host "Error: El nombre de usuario no puede iniciar con un número." -ForegroundColor Red
            continue
        }

        if ($NombresReservados -contains $NombreUsuario) {
            Write-Host "Error: El nombre de usuario no puede ser un nombre reservado del sistema." -ForegroundColor Red
            continue
        }

        if (Get-LocalUser -Name $NombreUsuario -ErrorAction SilentlyContinue) {
            Write-Host "Error: El nombre de usuario ya existe en el sistema, elija otro." -ForegroundColor Red
            continue
        }

        return $NombreUsuario  # Si es válido, lo retorna
    }
}

Export-ModuleMember -Function Validar-NombreUsuario