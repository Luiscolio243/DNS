function Cambiar-GrupoFTP {
    $NombreUsuario = Read-Host "Ingrese el nombre del usuario"

    if (-not (Get-LocalUser -Name $NombreUsuario -ErrorAction SilentlyContinue)) {
        Write-Host "Usuario no encontrado." -ForegroundColor Red
        return
    }

    $GrupoActual = if ((Get-LocalGroupMember -Group "reprobados" -Member $NombreUsuario -ErrorAction SilentlyContinue)) {
        "reprobados"
    } elseif ((Get-LocalGroupMember -Group "recursadores" -Member $NombreUsuario -ErrorAction SilentlyContinue)) {
        "recursadores"
    } else {
        Write-Host "El usuario no pertenece a ningún grupo." -ForegroundColor Red
        return 
    }

    $NuevoGrupo = if ($GrupoActual -eq "reprobados") { "recursadores" } else { "reprobados" }

    Remove-LocalGroupMember -Group $GrupoActual -Member $NombreUsuario
    net localgroup $NuevoGrupo $NombreUsuario /add

    Remove-Item "C:\FTP\LocalUser\$NombreUsuario\$GrupoActual" -Force
    cmd.exe /c mklink /d "C:\FTP\LocalUser\$NombreUsuario\$NuevoGrupo" "C:\FTP\$NuevoGrupo"

    # Actualizar permisos en IIS
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/$NombreUsuario" -Filter "system.ftpServer/security/authorization" -Name "."
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="$NombreUsuario";permissions=3} -PSPath IIS:\ -Location "FTPServidor/$NombreUsuario"

    # Eliminar cualquier configuración previa en IIS
    Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/$NuevoGrupo" -Filter "system.ftpServer/security/authorization" -Name "."
    # Asignar permisos al grupo "recursadores"
    Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="$NuevoGrupo";permissions=3} -PSPath IIS:\ -Location "FTPServidor/$NuevoGrupo"

    Restart-Service FTPSVC

    Write-Host "Usuario $NombreUsuario ahora pertenece a $NuevoGrupo." -ForegroundColor Green
}

Export-ModuleMember -Function Cambiar-GrupoFTP