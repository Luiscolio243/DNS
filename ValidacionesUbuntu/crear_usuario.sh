source gestionar_usuarios.sh

crear_usuario() {
    advertencias_nombre 
    nombre=$(validar_nombre_usuario)  # Pide primero el nombre
    advertencias_contrasena
    contrasena=$(validar_contrasena "$nombre")  # Luego la contraseña

    seleccionar_grupo  # Llamamos la función para obtener el grupo

    # Validar si la variable grupo tiene un valor válido
    if [[ -z "$grupo" ]]; then
        echo "Error: No se seleccionó un grupo válido."
        return
    fi

    echo "Creando usuario '$nombre' en el grupo '$grupo'..."

    # Verificar que adduser se ejecute correctamente
    if ! sudo adduser --disabled-password --gecos "" "$nombre"; then
        echo "Error: No se pudo crear el usuario."
        return
    fi

    # Verificar que la contraseña se asigna correctamente
    if ! echo "$nombre:$contrasena" | sudo chpasswd; then
        echo "Error: No se pudo asignar la contraseña."
        return
    fi
    
    # Crear carpeta específica del usuario
    sudo mkdir -p "/srv/ftp/$nombre"
    sudo chown "$nombre:ftp" "/srv/ftp/$nombre"
    sudo chmod 770 "/srv/ftp/$nombre"
    sudo chown $nombre:ftp /srv/ftp/publico
    sudo chmod 755 /srv/ftp/publico
    sudo chown $nombre:ftp /srv/ftp/publico/publico
    sudo chmod 755 /srv/ftp/publico/publico
    sudo chown $nombre:ftp /srv/ftp/$grupo
    sudo chmod 770 /srv/ftp/$grupo
    sudo mkdir -p "/srv/ftp/$nombre/$nombre"
    sudo chown $nombre:ftp /srv/ftp/$nombre/$nombre
    sudo chmod 770 /srv/ftp/$nombre/$nombre
    
    # Montar carpetas
    sudo mkdir -p "/srv/ftp/$nombre/publico"
    sudo mkdir -p "/srv/ftp/$nombre/$grupo"
    sudo chown $nombre:ftp /srv/ftp/$nombre/$grupo
    sudo chmod 755 /srv/ftp/$nombre/$grupo
    sudo mount --bind /srv/ftp/publico/publico "/srv/ftp/$nombre/publico"
    sudo mount --bind "/srv/ftp/$grupo" "/srv/ftp/$nombre/$grupo"
    
    echo "Usuario $nombre creado con acceso a su carpeta, la pública y la de $grupo."
}
