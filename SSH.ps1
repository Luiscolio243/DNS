
#Instalación del Servidor OpenSSH
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

#Iniciar el servicio SSHD
Start-Service sshd 

#Configurar el inicio automático del servicio
Set-Service -Name sshd -StartupType 'Automatic'

#Crear una regla de firewall para permitir conexiones SSH
New-NetFirewallRule -Name "sshd" -DisplayName "OpenSSH Server (ssh)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
