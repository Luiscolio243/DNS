$global:regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System"
 
$global:dominio = "plan-tres.com"
$global:ouPathC = "OU=cuates,DC=plan-tres,DC=com"
$global:ouPathNC = "OU=no cuates,DC=plan-tres,DC=com"

$global:gpoHorario1 = "RestriccionHorarioCuates"
$global:gpoHorario2 = "RestriccionHorarioNoCuates"

$global:gpoTam1 = "Grupo1Tam"
$global:gpoTam2 = "Grupo2Tam"

$global:gpoApp1 = "SoloBlocNotas"
$global:gpoApp2 = "BloquearBlocNotas"

function restriccion_horarios(){
    Import-Module GroupPolicy -ErrorAction SilentlyContinue
    
    function establecer_horario {
        param (
            [string]$UO,
            [byte[]]$Horario
        )

        $users = Get-ADUser -Filter * -SearchBase $UO
        foreach ($user in $users) {
            Set-ADUser -Identity $user -Replace @{logonHours = $Horario}
        }
    }

    $horarioC = @(0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63,0,128,63)  #8:00 am a 3:00 pm
    $horarioNC = @(255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192,255,1,192)  #3:00 pm a 2:00 am

    establecer_horario -UO $global:ouPathC -Horario $horarioC
    establecer_horario -UO $global:ouPathNC -Horario $horarioNC

    $gpo1Exist = Get-GPO -Name $global:gpoHorario1 -ErrorAction SilentlyContinue
    $gpo2Exist = Get-GPO -Name $global:gpoHorario2 -ErrorAction SilentlyContinue

    if (-not $gpo1Exist) {
        New-GPO -Name $global:gpoHorario1
        Write-Output "GPO '$global:gpoHorario1 ' creada."
    } else {
        Write-Output "La directiva '$global:gpoHorario1 ' ya existe, omitiendo creación y actualizando."
    }

    if (-not $gpo2Exist) {
        New-GPO -Name $global:gpoHorario2
        Write-Output "GPO '$global:gpoHorario2' creada."
    } else {
        Write-Output "La directiva '$global:gpoHorario2' ya existe, omitiendo creación y actualizando."
    }

    try {
        $linksC = (Get-GPInheritance -Target $global:ouPathC).GpoLinks | ForEach-Object { $_.DisplayName }
        if ($linksC -notcontains $global:gpoHorario1) {
            New-GPLink -Name $global:gpoHorario1 -Target $global:ouPathC
            Write-Output "GPO '$global:gpoHorario1' enlazada a '$global:ouPathC'."
        } else {
            Write-Output "La GPO '$global:gpoHorario1' ya está enlazada a '$global:ouPathC', omitiendo."
        }

        $linksNC = (Get-GPInheritance -Target $global:ouPathNC).GpoLinks | ForEach-Object { $_.DisplayName }
        if ($linksNC -notcontains $global:gpoHorario2) {
            New-GPLink -Name $global:gpoHorario2 -Target $global:ouPathNC
            Write-Output "GPO '$global:gpoHorario2' enlazada a '$global:ouPathNC'."
        } else {
            Write-Output "La GPO '$global:gpoHorario2' ya está enlazada a '$global:ouPathNC', omitiendo."
        }
    } catch {
        Write-Warning "No se pudo obtener el enlace de alguna OU. Asegúrate de estar ejecutando esto con permisos de administrador en un controlador de dominio con RSAT instalado."
    }

    $scriptPath = "powershell.exe -ExecutionPolicy Bypass -File \\$global:dominio \NETLOGON\horarios.ps1"

    Set-GPPrefRegistryValue -Name $global:gpoHorario1 -Context "Computer" `
        -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -ValueName "EjecutarHorarios" -Type "String" `
        -Value $scriptPath -Action Create

    Set-GPPrefRegistryValue -Name $global:gpoHorario2 -Context "Computer" `
        -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" `
        -ValueName "EjecutarHorarios" -Type "String" `
        -Value $scriptPath -Action Create
}

function restriccion_archivos(){
    $sharePath = "C:\Profiles\"
    $serverName = "WIN-EMVKRM56JFS"  
    $shareName = "Profiles"

    $gpo1 = Get-GPO -Name $global:gpoTam1 -ErrorAction SilentlyContinue

    if (-Not $gpo1) {
        $gpo1 = New-GPO -Name $global:gpoTam1
        Write-Output "GPO '$global:gpoTam1' creada."
    } else {
        Write-Output "GPO '$global:gpoTam1' ya existe."
    }

    $linksC = (Get-GPInheritance -Target $global:ouPathC).GpoLinks | ForEach-Object { $_.DisplayName }
    if ($linksC -notcontains $global:gpoTam1) {
        New-GPLink -Name $global:gpoTam1 -Target $global:ouPathC -LinkEnabled Yes
        Write-Output "Enlace a la OU '$global:ouPathC' creado para el GPO."
    } else {
        Write-Output "El GPO ya está enlazado a la OU '$global:ouPathC'."
    }

    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName EnableProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName IncludeProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName MaxProfileSize -Type DWord -Value 5000  
    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName ProfileQuotaMessage -Type String -Value "Limite de MB alcanzado (10 mb)"
    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName WarnUser -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam1 -Key $global:regPath -ValueName WarnUserTimeout -Type DWord -Value 10

    
    $gpo2 = Get-GPO -Name $global:gpoTam2 -ErrorAction SilentlyContinue

    if (-Not $gpo2) {
        $gpo2 = New-GPO -Name $global:gpoTam2
        Write-Output "GPO '$global:gpoTam2' creada."
    } else {
        Write-Output "GPO '$global:gpoTam2' ya existe."
    }

    $linksNC = (Get-GPInheritance -Target $global:ouPathNC).GpoLinks | ForEach-Object { $_.DisplayName }
    if ($linksNC -notcontains $global:gpoTam2) {
        New-GPLink -Name $global:gpoTam2 -Target $global:ouPathNC -LinkEnabled Yes
        Write-Output "Enlace a la OU '$global:ouPathNC' creado para el GPO."
    } else {
        Write-Output "El GPO ya está enlazado a la OU '$global:ouPathNC'."
    }

    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName EnableProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName IncludeProfileQuota -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName MaxProfileSize -Type DWord -Value 10000  # 10MB en KB
    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName ProfileQuotaMessage -Type String -Value "Limite de MB alcanzado (10 mb)"
    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName WarnUser -Type DWord -Value 1
    Set-GPRegistryValue -Name $global:gpoTam2 -Key $global:regPath -ValueName WarnUserTimeout -Type DWord -Value 10

    if (-Not (Test-Path -Path $sharePath)) {
        New-Item -ItemType Directory -Path $sharePath
        Write-Host "Carpeta creada: $sharePath"
    } else {
        Write-Host "La carpeta ya existe: $sharePath"
    }

    if (-Not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
        New-SmbShare -Path $sharePath -Name $shareName 
        Grant-SmbShareAccess -Name $shareName -AccountName Todos -AccessRight Full -Force
        Write-Host "Recurso compartido creado"
    } else {
        Write-Host "El recurso compartido '$shareName' ya existe."
    }

    $usersC = Get-ADUser -Filter * -SearchBase $global:ouPathC
    foreach ($user in $usersC) {
        $profilePath = "\\$serverName\$shareName\$($user.SamAccountName)"
        Set-ADUser -Identity $($user.SamAccountName) -ProfilePath $profilePath
    }

    $usersNC = Get-ADUser -Filter * -SearchBase $global:ouPathNC
    foreach ($user in $usersNC) {
        $profilePath = "\\$serverName\$shareName\$($user.SamAccountName)"
        Set-ADUser -Identity $($user.SamAccountName) -ProfilePath $profilePath
    }

    Invoke-GPUpdate -Force
    gpupdate /force
}

function restriccion_aplicaciones(){

    $gpo1 = Get-GPO -Name $global:gpoApp1 -ErrorAction SilentlyContinue

    if (-Not $gpo1) {
        $gpo1 = New-GPO -Name $global:gpoApp1
        Write-Output "GPO '$global:gpoApp1' creada."
    } else {
        Write-Output "GPO '$global:gpoApp1' ya existe."
    }

    $linksC = (Get-GPInheritance -Target $global:ouPathC).GpoLinks | ForEach-Object { $_.DisplayName }
    if ($linksC -notcontains $global:gpoApp1) {
        New-GPLink -Name $global:gpoApp1 -Target $global:ouPathC 
        Write-Output "Enlace a la OU '$global:ouPathC' creado para el GPO."
    } else {
        Write-Output "El GPO ya está enlazado a la OU '$global:ouPathC'."
    }

    Set-GPRegistryValue -Name $global:gpoApp1 -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "RestrictRun" -Type DWord -Value 1

    Set-GPRegistryValue -Name $global:gpoApp1  -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\RestrictRun" -ValueName "1" -Type String -Value "notepad.exe"


    $gpo2 = Get-GPO -Name $global:gpoApp2 -ErrorAction SilentlyContinue

    if (-Not $gpo2) {
        $gpo2 = New-GPO -Name $global:gpoApp2
        Write-Output "GPO '$global:gpoApp2' creada."
    } else {
        Write-Output "GPO '$global:gpoApp2' ya existe."
    }


    $linksNC = (Get-GPInheritance -Target $global:ouPathNC).GpoLinks | ForEach-Object { $_.DisplayName }
    if ($linksNC -notcontains $global:gpoApp2) {
        New-GPLink -Name $global:gpoApp2 -Target $global:ouPathNC 
        Write-Output "Enlace a la OU '$global:ouPathNC' creado para el GPO."
    } else {
        Write-Output "El GPO ya está enlazado a la OU '$global:ouPathNC'."
    }

    Set-GPRegistryValue -Name $global:gpoApp2 -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName DisallowRun -Type DWord -Value 1

    Set-GPRegistryValue -Name $global:gpoApp2 -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" -ValueName 1 -Type String -Value "notepad.exe"

}

function passwords_seguras(){
    Set-ADDefaultDomainPasswordPolicy -Identity "plan-tres.com" `
    -MinPasswordLength 8 `
    -ComplexityEnabled $true `
    -PasswordHistoryCount 1 `
    -MinPasswordAge "1.00:00:00" `
    -MaxPasswordAge "30.00:00:00"

    Get-ADDefaultDomainPasswordPolicy

    $usersC = Get-ADUser -Filter * -SearchBase $global:ouPathC
    foreach ($user in $usersC) {
        Set-ADUser -Identity $($user.SamAccountName) -ChangePasswordAtLogon $true
    }

    $usersNC = Get-ADUser -Filter * -SearchBase $global:ouPathNC
    foreach ($user in $usersNC) {
        Set-ADUser -Identity $($user.SamAccountName) -ChangePasswordAtLogon $true
    }
}

# 8
function habilitar_auditorias {
    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /category:`"Inicio/cierre de sesión`" /success:enable /failure:enable" -NoNewWindow -Wait
    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /category:`"Inicio de sesión de la cuenta`" /success:enable /failure:enable" -NoNewWindow -Wait

    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /subcategory:`"Acceso del servicio de directorio`" /success:enable /failure:enable" -NoNewWindow -Wait
    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /subcategory:`"Cambios de servicio de directorio`" /success:enable /failure:enable" -NoNewWindow -Wait

    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /subcategory:`"Administración de cuentas de usuario`" /success:enable /failure:enable" -NoNewWindow -Wait
    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /subcategory:`"Administración de cuentas de grupos de seguridad`" /success:enable /failure:enable" -NoNewWindow -Wait
    Start-Process -FilePath "auditpol.exe" -ArgumentList "/set /subcategory:`"Administración de cuentas de equipo`" /success:enable /failure:enable" -NoNewWindow -Wait
}
