# Importar funciones de validación
. .\Validaciones.ps1

# Función para solicitar una dirección IP válida al usuario
function ObtenerIPValida {
    param (
        [string]$mensaje
    )
    while ($true) {
        $ip = Read-Host $mensaje
        if (ValidarIP -ip $ip) {
            Write-Host "¡Dirección IP válida ingresada: $ip!"
            return $ip
        } else {
            Write-Host "La dirección IP ingresada no es válida. Por favor, inténtelo nuevamente."
        }
    }
}

# Función para obtener un rango de IP válido
function ObtenerRangoValido {
    param (
        [string]$ip_inicio
    )
    while ($true) {
        # Solicita la IP final del rango
        $ip_fin = ObtenerIPValida -mensaje "Ingrese la IP de fin del rango DHCP"
        
        # Extrae el último octeto de las IPs de inicio y fin
        $octeto_fin = [int]($ip_fin -split '\.')[3]
        $octeto_inicio = [int]($ip_inicio -split '\.')[3]

        # Verifica que la IP de fin tenga un último octeto mayor que la de inicio
        if ($octeto_fin -gt $octeto_inicio) {
            Write-Host "IP de fin válida: $ip_fin"
            return $ip_fin
        } else {
            Write-Host "La IP final debe tener el último octeto mayor que la IP inicial."
        }
    }
}