source gestionar_usuarios.sh
source crear_usuario.sh
source cambiar_grupo.sh

while true; do
    read -p "¿Desea habilitar SSL para vsftpd? (s/n): " ssl_choice
    ssl_choice=${ssl_choice,,}  # Convertir a minúsculas

    if [[ "$ssl_choice" == "s" || "$ssl_choice" == "n" ]]; then
        break  # Salir del bucle si la entrada es válida
    else
        echo "Error: Solo se permite 's' o 'n'. Inténtelo de nuevo."
    fi
done


# Aplicar configuración de red y FTP
bash configurar_ip.sh
bash configuracion_ftp.sh "$ssl_choice"

while true; do
    echo -e "\n=== Menú FTP ==="
    echo "1. Crear usuario"
    echo "2. Cambiar de grupo"
    echo "3. Salir"
    read -r -p "Seleccione una opción: " opcion

    case $opcion in
        1) crear_usuario ;;  # Llama directamente a la función
        2) cambiar_grupo ;;  # Llama directamente a la función
        3) echo "Saliendo..."; exit 0 ;;
        *) echo "Error: Opción no válida." ;;
    esac
done