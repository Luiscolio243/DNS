function Get-LogonsUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$user  # SamAccountName del usuario
    )

    # Obtener DN del usuario y nombre de dominio
    $userData = Get-ADUser -Identity $user -Properties DistinguishedName -ErrorAction SilentlyContinue
    if (-not $userData) {
        Write-Host "Usuario '$user' no encontrado."
        return
    }
    
    $userDN = $userData.DistinguishedName
    $domain = (Get-ADDomain).DNSRoot

    # Event IDs a buscar
    $userEvents = @(4624,4625,4648,4720,4722,4725,4738,4662,5136)

    try {
        $events = Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=$($userEvents -join ' or EventID=')]]" -MaxEvents 100 -ErrorAction Stop |
                  Where-Object { 
                      # Para eventos de logon (4624,4625,4648)
                      if ($_.Id -in (4624,4625,4648)) {
                          $_.Properties[5].Value -like "*\$user" -or  # DOMINIO\usuario
                          $_.Properties[5].Value -eq $user             # usuario solo
                      }
                      # Para otros eventos de AD
                      else {
                          $_.Properties[4].Value -eq $userDN -or 
                          $_.Properties[5].Value -eq $user
                      }
                  }

        if (-not $events) {
            Write-Host "No hay inicios de sesion registrados del usuario '$user'."
            return
        }

        $report = $events | ForEach-Object {
            [PSCustomObject]@{
                Fecha      = $_.TimeCreated
                EventoID   = $_.Id
                Accion     = switch ($_.Id) {
                    4624 { "Inicio de sesion exitoso" }
                    4625 { "Inicio de sesion fallido" }
                    4648 { "Logon con credenciales explícitas" }
                    4720 { "Usuario creado" }
                    4722 { "Contraseña cambiada" }
                    4725 { "Usuario deshabilitado" }
                    4738 { "Membresía de grupo modificada" }
                    4662 { "Acceso a objeto AD" }
                    5136 { "Atributo modificado" }
                    default { "Otro" }
                }
                # Mapeo correcto según tipo de evento
                Usuario    = if ($.Id -in (4624,4625,4648)) { $.Properties[5].Value } else { $_.Properties[5].Value }
                IP_Origen  = if ($.Id -in (4624,4625,4648)) { $.Properties[18].Value } else { "N/A" }
                Objetivo   = if ($.Id -in (4624,4625,4648)) { $.Properties[6].Value } else { $_.Properties[4].Value }
            }
        }

        # Ordenamos por fecha descendente y mostramos
        $report | Sort-Object Fecha -Descending -Unique | Format-Table -AutoSize
    }
    catch {
        Write-Host "Error al leer eventos: $_" -ForegroundColor Red
    }
}

# Función para auditoría general de AD (equivalente a Get-ADAuditEvents)
function Get-ADEvents {
    [CmdletBinding()]
    param ()

    # Event IDs clave para AD (personalizable)
    $targetEvents = @(4662, 4738, 4720, 4726, 4767)

    try {
        $events = Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=$($targetEvents -join ' or EventID=')]]" -MaxEvents 1000 -ErrorAction Stop

        $report = $events | ForEach-Object {
            [PSCustomObject]@{
                Fecha      = $_.TimeCreated
                EventoID   = $_.Id
                Accion     = switch ($_.Id) {
                    4662 { "Acceso a objeto AD" }
                    4738 { "Cambio en grupo (membresia)" }
                    4720 { "Usuario creado" }
                    4726 { "Usuario eliminado" }
                    4767 { "Cambio en cuenta de servicio" }
                    default { "Otro" }
                }
                Usuario    = $_.Properties[5].Value
                Objetivo   = $_.Properties[4].Value
            }
        }

        $report | Sort-Object Fecha -Descending -Unique | Format-Table -AutoSize
    }
    catch {
        Write-Host "Error al leer eventos: $_" -ForegroundColor Red
    }
}