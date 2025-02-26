# Importar funciones de los otros archivos
. .\Validaciones.ps1
. .\SolicitudesDHCP.ps1
. .\ConfiguracionDHCP.ps1

# Solicitar la dirección IP del servidor DNS
$ip_servidor = ObtenerIPValida -mensaje "Ingrese la dirección IP del servidor DNS"

# Solicitar la IP de inicio del rango DHCP
$ip_inicio = ObtenerIPValida -mensaje "Ingrese la IP de inicio del rango DHCP"

# Solicitar la IP de fin del rango DHCP
$ip_fin = ObtenerRangoValido -ip_inicio $ip_inicio

# Configurar el servidor DHCP
ConfigurarDHCP -ip_servidor $ip_servidor -ip_inicio $ip_inicio -ip_fin $ip_fin