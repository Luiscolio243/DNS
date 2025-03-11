advertencias_nombre() {
    echo -e "\n=== ADVERTENCIAS ==="
    echo "1. El nombre de usuario debe tener entre 1 y 20 caracteres."
    echo "2. El nombre de usuario no puede contener caracteres especiales."
    echo "3. El nombre de usuario no puede ser solo números, debe incluir al menos una letra."
    echo "4. El nombre de usuario no puede estar vacío."
    echo "5. El nombre de usuario no puede tener letras mayúsculas."
    echo "6. El nombre de usuario no puede tener espacios en blanco."
    echo "7. El nombre de usuario no puede ser un nombre reservado del sistema."
    echo "8. El nombre de usuario no puede ser uno que ya existe."
    echo "8. El nombre de usuario no debe de empezar con numeros."
}

advertencias_contrasena() {
    echo -e "\n=== ADVERTENCIAS ==="
    echo "1. La contraseña debe tener entre 3 y 14 caracteres"
    echo "2. La contraseña no debe contener el nombre de usuario en ella"
    echo "3. La contraseña debe contener al menos una letra, un numero y un caracter especial"
}

NOMBRES_RESERVADOS=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "nobody" "systemd-network")

validar_nombre_usuario() {
    while true; do
        read -p "Ingrese el nombre del usuario: " nombre
        nombre=$(echo "$nombre" | tr -d ' ')  # Eliminar espacios en blanco

        if [[ "$nombre" =~ ^[0-9] ]]; then
            continue
        fi

        if [[ -z "$nombre" ]]; then
            continue
        fi

        # Verificar que no contenga mayúsculas
        if [[ "$nombre" =~ [A-Z] ]]; then
            continue
        fi

        if [[ ${#nombre} -lt 1 || ${#nombre} -gt 8 ]]; then
            continue
        fi

        if [[ "$nombre" =~ [^a-zA-Z0-9] ]]; then
            continue
        fi

        if [[ "$nombre" =~ ^[0-9]+$ ]]; then
            continue
        fi

        if [[ " ${NOMBRES_RESERVADOS[@]} " =~ " $nombre " ]]; then
            continue
        fi

        if id "$nombre" &>/dev/null; then
            continue
        fi

        echo "$nombre"
        return
    done
}

validar_contrasena() {
    local nombre_usuario=$1
    while true; do
        read -p "Ingrese contraseña: " contrasena

        # Validar longitud de la contraseña
        if [[ ${#contrasena} -lt 8 || ${#contrasena} -gt 14 ]]; then
            continue
        fi

        # Validar que la contraseña no contenga el nombre de usuario
        if [[ "$contrasena" == *"$nombre_usuario"* ]]; then
            continue
        fi

        # Reiniciar variables de validación
        tiene_numero=1
        tiene_letra=1
        tiene_especial=1

        # Verificar si contiene número
        if [[ "$contrasena" =~ [0-9] ]]; then
            tiene_numero=0
        fi

        # Verificar si contiene letra (mayúscula o minúscula)
        if [[ "$contrasena" =~ [A-Za-z] ]]; then
            tiene_letra=0
        fi

        # Verificar si contiene al menos un carácter especial
        if [[ "$contrasena" =~ [\!\@\#\$\%\^\&\*\(\)\,\.\?\"\'\{\}\|\<\>] ]]; then
            tiene_especial=0
        fi

        # Si falta algún requisito, mostrar error
        if [[ $tiene_numero -ne 0 || $tiene_letra -ne 0 || $tiene_especial -ne 0 ]]; then
            continue
        fi

        # Si pasa todas las validaciones, retornamos la contraseña
        echo "$contrasena"
        return
    done
}

seleccionar_grupo() {
    local grupo_opcion 
    grupo=""  # Asegurar que esté vacía antes de usar

    while true; do
        echo -e "\nSeleccione el grupo:"
        echo "1. Reprobados"
        echo "2. Recursadores"
        read -p "Seleccione una opción: " grupo_opcion

        case "$grupo_opcion" in
            1) grupo="reprobados"; return ;;  # Usamos `return` para salir correctamente
            2) grupo="recursadores"; return ;;
            *) echo "Error: Debe seleccionar 1 o 2." ;;
        esac
    done
}
