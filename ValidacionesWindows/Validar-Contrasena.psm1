function Validar-Contrasena {
    param ([string]$NombreUsuario)

    while ($true) {
        $Password = Read-Host "Ingrese contraseña"

        if ($Password -eq "") {
            Write-Host "Error: La contraseña no puede estar vacía." -ForegroundColor Red
            continue
        }

        if ($Password.Length -lt 8 -or $Password.Length -gt 14) {
            Write-Host "Error: La contraseña debe tener entre 8 y 14 caracteres." -ForegroundColor Red
            continue
        }

        if ($Password -match [regex]::Escape($NombreUsuario)) {
            Write-Host "Error: La contraseña no puede contener el nombre de usuario." -ForegroundColor Red
            continue
        }

        # Verifica los requisitos de la contraseña
        $TieneNumero = $Password -cmatch "\d"  # Requiere al menos un número
        $TieneEspecial = $Password -cmatch "[!@#$%^&*(),.?""{}|<>]"  # Requiere un carácter especial
        $TieneMayuscula = $Password -cmatch "[A-Z]"
        $TieneMinuscula = $Password -cmatch "[a-z]"

        if (-not $TieneNumero -or -not $TieneEspecial -or -not $TieneMayuscula -or -not $TieneMinuscula) {
            Write-Host "Error: La contraseña debe contener al menos: un número, un carácter especial, una letra minuscula y una letra mayuscula." -ForegroundColor Red
            continue
        }

        return $Password 
    }
}

Export-ModuleMember -Function Validar-Contrasena