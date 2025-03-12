function Configurar-FTP {
# Instalación del Servidor FTP en Windows Server
netsh interface ipv4 set address name="Ethernet 2" static 192.168.1.11 255.255.255.0
Install-WindowsFeature -Name Web-Ftp-Server, Web-Server -IncludeManagementTools
Import-Module WebAdministration

# Creación de Carpetas
mkdir C:\FTP
mkdir C:\FTP\publica
mkdir C:\FTP\reprobados
mkdir C:\FTP\recursadores
mkdir C:\FTP\LocalUser
mkdir C:\FTP\LocalUser\Public

# Verificar que las carpetas existen antes de continuar
if (!(Test-Path "C:\FTP\publica")) { mkdir "C:\FTP\publica" }
if (!(Test-Path "C:\FTP\reprobados")) { mkdir "C:\FTP\reprobados" }
if (!(Test-Path "C:\FTP\recursadores")) { mkdir "C:\FTP\recursadores" }
if (!(Test-Path "C:\FTP\LocalUser")) { mkdir "C:\FTP\LocalUser" }
if (!(Test-Path "C:\FTP\LocalUser\Public")) { mkdir "C:\FTP\LocalUser\Public" }

# Crear el Sitio FTP en IIS
New-WebFtpSite -Name "FTPServidor" -Port 21 -PhysicalPath "C:\FTP"

# Configuración de autenticación
Set-ItemProperty "IIS:\Sites\FTPServidor" -Name ftpServer.security.authentication.basicAuthentication.enabled -Value 1
Set-ItemProperty "IIS:\Sites\FTPServidor" -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value 1

Set-ItemProperty "IIS:\Sites\FTPServidor" -Name ftpServer.userIsolation.mode -Value "IsolateRootDirectoryOnly"

cmd /c mklink /d "C:\FTP\LocalUser\Public\publica" "C:\FTP\publica"

# Crear Grupos de Usuarios si no existen
if (!(Get-LocalGroup -Name "reprobados" -ErrorAction SilentlyContinue)) {
    net localgroup "reprobados" /add
}
if (!(Get-LocalGroup -Name "recursadores" -ErrorAction SilentlyContinue)) {
    net localgroup "recursadores" /add
}
if (!(Get-LocalGroup -Name "publica" -ErrorAction SilentlyContinue)) {
    net localgroup "publica" /add
}

Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=3} -PSPath IIS:\ -Location "FTPServidor"

# Eliminar configuraciones previas en las carpetas
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/publica" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/reprobados" -Filter "system.ftpServer/security/authorization" -Name "."
Remove-WebConfigurationProperty -PSPath IIS:\ -Location "FTPServidor/recursadores" -Filter "system.ftpServer/security/authorization" -Name "."

# Asignar permisos específicos a cada grupo con `Add-WebConfiguration`
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";users="*";permissions=1} -PSPath IIS:\ -Location "FTPServidor/publica"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="reprobados";permissions=3} -PSPath IIS:\ -Location "FTPServidor/reprobados"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="recursadores";permissions=3} -PSPath IIS:\ -Location "FTPServidor/recursadores"
Add-WebConfiguration "/system.ftpServer/security/authorization" -Value @{accessType="Allow";roles="publica";permissions=3} -PSPath IIS:\ -Location "FTPServidor/publica"


# Deshabilitar SSL en el FTP
Set-ItemProperty "IIS:\Sites\FTPServidor" -Name ftpServer.security.ssl.controlChannelPolicy -Value 0
Set-ItemProperty "IIS:\Sites\FTPServidor" -Name ftpServer.security.ssl.dataChannelPolicy -Value 0

Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Configurar Firewall
New-NetFirewallRule -DisplayName "FTP (Puerto 21)" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
New-NetFirewallRule -DisplayName "FTP PASV (50000-51000)" -Direction Inbound -Protocol TCP -LocalPort 50000-51000 -Action Allow
}

Export-ModuleMember -Function Configurar-FTP