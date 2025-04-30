# Cargar módulos de validación
Import-Module "C:\Users\Administrador\Desktop\ValidacionesWindows\Validar-NombreUsuario.psm1"
Import-Module "C:\Users\Administrador\Desktop\ValidacionesWindows\Validar-Contrasena.psm1"

# Crear OUs si no existen
$ous = @("OU=Cuates,DC=luiscolio,DC=com", "OU=NoCuates,DC=luiscolio,DC=com")
foreach ($ou in $ous) {
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ou'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name ($ou -split ",")[0].Split("=")[1] -Path "DC=luiscolio,DC=com"
        Write-Host "OU creada: $ou"
    }
}

# Menú para elegir OU
do {
    Write-Host "`n¿En qué unidad organizativa quieres crear el usuario?"
    Write-Host "1. Cuates"
    Write-Host "2. NoCuates"
    $ouOption = Read-Host "Escribe 1 o 2"
} while ($ouOption -ne "1" -and $ouOption -ne "2")

$ouPath = if ($ouOption -eq "1") { "OU=Cuates,DC=luiscolio,DC=com" } else { "OU=NoCuates,DC=luiscolio,DC=com" }

# Llamar a las funciones que ya se encargan de pedir y validar
$username = Validar-NombreUsuario
$password = Validar-Contrasena

# Crear usuario en el dominio
New-ADUser -Name $username `
           -SamAccountName $username `
           -UserPrincipalName "$username@luiscolio.com" `
           -AccountPassword ($password | ConvertTo-SecureString -AsPlainText -Force) `
           -Enabled $true `
           -Path $ouPath `
           -ChangePasswordAtLogon $false

Write-Host "Usuario '$username' creado exitosamente en la OU $ouPath." -ForegroundColor Green
