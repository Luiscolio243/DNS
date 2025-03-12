Import-Module "C:\Users\Administrador\Desktop\ValidacionesWindows\Validar-NombreUsuario.psm1"
Import-Module "C:\Users\Administrador\Desktop\ValidacionesWindows\Validar-Contrasena.psm1"
function Crear-UsuarioFTP {
    $NombreUsuario = Validar-NombreUsuario  # Se asegura que sea válido antes de continuar
    $Password = Validar-Contrasena -NombreUsuario $NombreUsuario  # Se asegura que la contraseña sea válida

    while ($true) {
        $opcionGrupo = Read-Host "Seleccione el grupo: 1 para Reprobados, 2 para Recursadores"
        
        if ($opcionGrupo -eq "1") {
            $Grupo = "reprobados"
            break  # Salimos del bucle porque ya es válido
        } elseif ($opcionGrupo -eq "2") {
            $Grupo = "recursadores"
            break  # Salimos del bucle porque ya es válido
        } else {
            Write-Host "Error: Debe seleccionar 1 para Reprobados o 2 para Recursadores." -ForegroundColor Red
            continue  # Repite la selección del grupo
        }
    }

    net user $NombreUsuario $Password /add
    net localgroup $Grupo $NombreUsuario /add
    net localgroup "publica" $NombreUsuario /add

    # Crear carpeta del usuario y vincular carpetas públicas y de grupo
    if (!(Test-Path "C:\FTP\$NombreUsuario")) { mkdir "C:\FTP\$NombreUsuario" }
    if (!(Test-Path "C:\FTP\LocalUser\$NombreUsuario")) { mkdir "C:\FTP\LocalUser\$NombreUsuario" }

    # Vincular carpetas públicas y de grupo
    cmd /c mklink /d "C:\FTP\LocalUser\$NombreUsuario\publica" "C:\FTP\publica"
    cmd /c mklink /d "C:\FTP\LocalUser\$NombreUsuario\$Grupo" "C:\FTP\$Grupo"
    cmd /c mklink /d "C:\FTP\LocalUser\$NombreUsuario\$NombreUsuario" "C:\FTP\$NombreUsuario"

    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/$NombreUsuario" -Filter "system.ftpServer/security/authorization" -Name "."

    # Asignar permisos al usuario en IIS en su propia carpeta
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="$NombreUsuario";permissions=3} -PSPath IIS:\ -Location "FTPServidor/$NombreUsuario"

    Write-Host "Usuario $NombreUsuario creado en el grupo $Grupo." -ForegroundColor Green
}

Export-ModuleMember -Function Crear-UsuarioFTP