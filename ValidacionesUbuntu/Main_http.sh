#!/bin/bash

source "./menu_http.sh"
source "./obtener_version.sh"
source "./solicitar_ver.sh"
source "./solicitar_puerto.sh"
source "./conf_http.sh"
source "./FTP-HTTP.sh"

if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root" 
    exit 1
fi

sudo apt install net-tools -y > /dev/null 2>&1

preguntar_ssl() {
    local respuesta
    while true; do
        read -p "¿Quieres activar SSL? (s/n): " respuesta
        respuesta=$(echo "$respuesta" | tr '[:upper:]' '[:lower:]')
        if [[ "$respuesta" == "s" || "$respuesta" == "n" ]]; then
            echo "$respuesta"
            return
        else
            echo "Entrada no válida. Debes ingresar 's' o 'n'." >&2
        fi
    done
}

while true; do
    clear
    echo "========== MENU PRINCIPAL =========="
    echo "1) Instalación por HTTP"
    echo "2) Instalación por FTP"
    echo "0) Salir"
    echo "===================================="
    read -p "Seleccione una opción: " opcion

    case $opcion in
        1)
            while true; do
            menu_http
            read -p "Seleccione el servicio HTTP que queria instalar y configurar: " op
                    
            if [ "$op" -eq 1 ]; then
                versions=$(obtener_version "Apache")
                stable=$(echo "$versions" | head -1)
                menu_http2 "Apache" "$stable" " "
                echo "Elija una version: "
                op2=$(solicitar_ver "Apache") 
                if [ "$op2" -eq 1 ]; then
                    port=$(solicitar_puerto)
                    if [[ -z "$port" ]]; then
                        continue
                    fi
                    ssl=$(preguntar_ssl)
                    conf_apache "$port" "$stable" "$ssl"
                elif [ "$op2" -eq 2 ]; then
                    continue
                fi
            elif [ "$op" -eq 3 ]; then
                versions=$(obtener_version "Nginx")
                stable=$(echo "$versions" | tail -n 2 | head -1)
                mainline=$(echo "$versions" | tail -1)
                menu_http2 "Nginx" "$stable" "$mainline"
                echo "Elija una version: "
                op2=$(solicitar_ver "Nginx")
                if [ "$op2" -eq 1 ]; then  
                    port=$(solicitar_puerto)
                    if [[ -z "$port" ]]; then
                        continue
                    fi
                    ssl=$(preguntar_ssl)
                    conf_nginx "$port" "$stable" "$ssl"
                elif [ "$op2" -eq 2 ]; then
                    port=$(solicitar_puerto)
                    if [[ -z "$port" ]]; then
                        continue
                    fi
                    ssl=$(preguntar_ssl)
                    conf_nginx "$port" "$mainline" "$ssl"
                elif [ "$op2" -eq 3 ]; then
                    continue
                fi
            elif [ "$op" -eq 2 ]; then
                versions=$(obtener_version "OpenLiteSpeed")
                stable=$(echo "$versions" | tail -n 2 | head -1)
                mainline=$(echo "$versions" | tail -1)
                menu_http2 "OpenLiteSpeed" "$stable" "$mainline"
                echo "Elija una version: "
                op2=$(solicitar_ver "OpenLiteSpeed")
                if [ "$op2" -eq 1 ]; then
                    port=$(solicitar_puerto)
                    if [[ -z "$port" ]]; then
                        continue
                    fi
                    ssl=$(preguntar_ssl)
                    conf_litespeed "$port" "$stable" "$ssl"
                elif [ "$op2" -eq 2 ]; then 
                    port=$(solicitar_puerto)
                    if [[ -z "$port" ]]; then
                        continue
                    fi
                    ssl=$(preguntar_ssl)
                    conf_litespeed "$port" "$mainline" "$ssl"
                elif [ "$op2" -eq 3 ]; then
                    continue
                fi
            elif [ "$op" -eq 4 ]; then
                echo "Regresando al menu prinicipal..."
                break
            else
                echo "Opción no válida"
            fi
        done
            read -p "Presiona Enter para volver al menú..."
            ;;
        2)
            carpetas=($(listar_carpetas_ftp))

            if [ ${#carpetas[@]} -eq 0 ]; then
                echo "No se encontraron carpetas en el FTP."
                read -p "Presiona Enter para volver al menú..."
                continue
            fi

            echo "========== CARPETAS DISPONIBLES EN EL FTP =========="
            for i in "${!carpetas[@]}"; do
                echo "$((i + 1)). ${carpetas[$i]}"
            done
            echo "$(( ${#carpetas[@]} + 1 )). Regresar"

            read -p "Selecciona la carpeta (1-${#carpetas[@]}): " carpeta_num
            if ! [[ "$carpeta_num" =~ ^[0-9]+$ ]] || [ "$carpeta_num" -lt 1 ] || [ "$carpeta_num" -gt "${#carpetas[@]}" ]; then
                echo "Regreando al menu principal..."
                continue
            fi

            carpeta_seleccionada="${carpetas[$((carpeta_num - 1))]}"
            echo "Seleccionaste la carpeta: $carpeta_seleccionada"

            archivos=()
            mapfile -t archivos < <(listar_archivos_ftp "$carpeta_seleccionada")

            if [ ${#archivos[@]} -eq 0 ]; then
                echo "No se encontraron archivos en la carpeta."
                exit 1
            fi

            echo "========== ARCHIVOS DISPONIBLES EN '$carpeta_seleccionada' =========="
            for i in "${!archivos[@]}"; do
                nombre="${archivos[$i]}"

                if [[ $carpeta_seleccionada == "Apache" ]]; then
                    # Extraer solo la versión
                    if [[ $nombre =~ httpd-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                        version="${BASH_REMATCH[1]}"
                        echo "$((i + 1)). Versión LTS: $version"
                    fi

                elif [[ $carpeta_seleccionada == "Nginx" || $carpeta_seleccionada == "OpenLiteSpeed" ]]; then
                    # Extraer versión de nginx o openlitespeed
                    if [[ $nombre =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                        version="${BASH_REMATCH[1]}"
                        if [ "$i" -eq 0 ]; then
                            echo "$((i + 1)). Versión LTS: $version"
                        else
                            echo "$((i + 1)). Versión Desarrollo: $version"
                        fi
                    else
                        echo "$((i + 1)). $nombre"
                    fi
                else
                    echo "$((i + 1)). $nombre"
                fi
            done
            echo "$(( ${#archivos[@]} + 1 )). Regresar"

            # Pedir selección de archivo solo por número
            read -p "Selecciona el archivo a descargar (1-${#archivos[@]}): " archivo_num
            if ! [[ "$archivo_num" =~ ^[0-9]+$ ]] || [ "$archivo_num" -lt 1 ] || [ "$archivo_num" -gt "${#archivos[@]}" ]; then
                echo "Regresando al menu principal..."
                continue
            fi

            archivo_seleccionado="${archivos[$((archivo_num - 1))]}"
            echo "Seleccionaste el archivo: $archivo_seleccionado"
            descargar_y_descomprimir "$carpeta_seleccionada" "$archivo_seleccionado"

            if [[ "$carpeta_seleccionada" == "Apache" ]]; then
                if [[ $archivo_seleccionado =~ httpd-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    version_apache="${BASH_REMATCH[1]}"
                    echo "Versión detectada de Apache: $version_apache"
                else
                    echo "No se pudo obtener la versión de Apache"
                    exit 1
                fi

                # Pedir el puerto
                port=$(solicitar_puerto)
                if [[ -z "$port" ]]; then
                    echo "No ingresaste puerto. Cancelando..."
                    exit 1
                fi

                # Preguntar por SSL
                ssl=$(preguntar_ssl)

                # Llamar a la función que configura Apache y pasarle la versión bien extraída
                configurar_apache "$port" "$version_apache" "$ssl"

            elif [[ "$carpeta_seleccionada" == "Nginx" ]]; then
                if [[ $archivo_seleccionado =~ nginx-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    version_nginx="${BASH_REMATCH[1]}"
                    echo "Versión detectada de NGINX: $version_nginx"
                else
                    echo "No se pudo obtener la versión de NGINX"
                    exit 1
                fi

                port=$(solicitar_puerto)
                if [[ -z "$port" ]]; then
                    echo "No ingresaste puerto. Cancelando..."
                    exit 1
                fi

                ssl=$(preguntar_ssl)
                configurar_nginx "$port" "$version_nginx" "$ssl" "$ip"


            elif [[ "$carpeta_seleccionada" == "OpenLiteSpeed" ]]; then
                if [[ $archivo_seleccionado =~ openlitespeed-([0-9]+\.[0-9]+\.[0-9]+) ]]; then
                    version_openlitespeed="${BASH_REMATCH[1]}"
                    echo "Versión detectada de OpenLiteSpeed: $version_openlitespeed"
                else
                    echo "No se pudo obtener la versión de OpenLiteSpeed"
                    exit 1
                fi

                # Pedir el puerto
                port=$(solicitar_puerto)
                if [[ -z "$port" ]]; then
                    echo "No ingresaste puerto. Cancelando..."
                    exit 1
                fi

                # Preguntar por SSL
                ssl=$(preguntar_ssl)

                # Llamar a la función que configura OpenLiteSpeed
                configurar_openlitespeed "$port" "$version_openlitespeed" "$ssl"

            else
                echo "Servicio no válido seleccionado."
                continue
            fi


            read -p "Presiona Enter para volver al menú..."
            ;;
        0)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida, intenta de nuevo."
            read -p "Presiona Enter para continuar..."
            ;;
    esac
done

