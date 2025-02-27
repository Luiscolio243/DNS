# Importar funciones de los otros archivos
. .\Validaciones.ps1
. .\ConfiguracionRed.ps1
. .\ConfiguracionDNS.ps1

# Solicitar IP del servidor DNS
do {
    $direccionIP = Read-Host "Ingrese la IP del servidor DNS"
    if (ValidarIP $direccionIP) {
        Write-Host "Dirección IP válida: $direccionIP" -ForegroundColor Green
        break
    } else {
        Write-Host "IP inválida. Intente de nuevo." -ForegroundColor Red
    }
} while ($true)

# Solicitar dominio
do {
    $nombreDominio = Read-Host "Ingrese el nombre de dominio"
    if (VerificarNombreDominio $nombreDominio) {
        Write-Host "Dominio válido: $nombreDominio" -ForegroundColor Green
        break
    } else {
        Write-Host "El dominio debe terminar en '.com'. Intente nuevamente." -ForegroundColor Red
    }
} while ($true)

# Dividir la IP en segmentos y construir la IP inversa
$segmentos = $direccionIP -split '\.'
$segmentoTres = "$($segmentos[0]).$($segmentos[1]).$($segmentos[2])"
$ipReversa = "$($segmentos[2]).$($segmentos[1]).$($segmentos[0]).in-addr.arpa"

$subnetMask = "255.255.255.0"

# Configurar IP fija y DNS
ConfigurarIPyDNS -direccionIP $direccionIP -subnetMask $subnetMask

# Instalar servicio DNS
InstalarServicioDNS

# Crear zonas DNS
CrearZonasDNS -nombreDominio $nombreDominio -ipReversa $ipReversa

# Agregar registros DNS
AgregarRegistrosDNS -nombreDominio $nombreDominio -direccionIP $direccionIP

# Configurar cliente DNS
ConfigurarClienteDNS -direccionIP $direccionIP

# Configurar firewall para permitir ICMP
ConfigurarFirewall

# Mostrar registros DNS
MostrarRegistrosDNS -nombreDominio $nombreDominio