advertencias_nombre() {
    echo -e "\n ¡ATENCIÓN! REGLAS PARA TU NOMBRE DE USUARIO "
    echo "Tu nombre debe tener entre 1 y 20 caracteres, ni más ni menos."
    echo "Nada de símbolos extraños como @, #, $, %, ¡solo letras y números!"
    echo "No puedes usar solo números, al menos una letra debe estar presente."
    echo "¿Dejarlo en blanco? Ni lo pienses, elige algo."
    echo "Mayúsculas no permitidas, todo en minúsculas por favor."
    echo "No uses espacios, el nombre debe ser una sola palabra."
    echo "Si el nombre ya está tomado, busca otra opción."
    echo "No puede empezar con un número, pon primero una letra."
    echo "Sigue estas reglas y estarás listo para continuar."
}

advertencias_contrasena() {
    echo -e "\n RESTRICCIONES DE CONTRASEÑA "
    echo "Longitud permitida: mínimo 3 y máximo 14 caracteres."
    echo "No debe contener el identificador del usuario."
    echo "Debe incluir al menos un número, un símbolo especial y una letra."
}


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

        if [[ ${#nombre} -lt 1 || ${#nombre} -gt 20 ]]; then
            continue
        fi

        if [[ "$nombre" =~ [^a-zA-Z0-9] ]]; then
            continue
        fi

        if [[ "$nombre" =~ ^[0-9]+$ ]]; then
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
