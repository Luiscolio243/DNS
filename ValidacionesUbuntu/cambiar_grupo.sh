
cambiar_grupo() {
    read -p "Ingrese el nombre del usuario a cambiar de grupo: " nombre
    
    if ! id "$nombre" &>/dev/null; then
        echo "El usuario no existe."
        return
    fi
    
    grupo_actual=""
    if [[ -d "/srv/ftp/$nombre/reprobados" ]]; then
        grupo_actual="reprobados"
    elif [[ -d "/srv/ftp/$nombre/recursadores" ]]; then
        grupo_actual="recursadores"
    else
        echo "El usuario no tiene grupo asignado."
        return
    fi
    
    nuevo_grupo=""
    if [[ "$grupo_actual" == "reprobados" ]]; then
        nuevo_grupo="recursadores"
    else
        nuevo_grupo="reprobados"
    fi
    
    # Montar carpetas nuevamente
    sudo umount -l "/srv/ftp/$nombre/$grupo_actual"
    sudo rm -r "/srv/ftp/$nombre/$grupo_actual"


    sudo chown $nombre:ftp /srv/ftp/$nuevo_grupo
    sudo chmod 770 /srv/ftp/$nuevo_grupo
    sudo mkdir -p "/srv/ftp/$nombre/$nuevo_grupo"
    sudo chown "$nombre:ftp" "/srv/ftp/$nombre/$nuevo_grupo"
    sudo chmod 770 /srv/ftp/$nombre/$grupo
    #sudo usermod -G "$nuevo_grupo" "$nombre"
    
    sudo mount --bind "/srv/ftp/$nuevo_grupo" "/srv/ftp/$nombre/$nuevo_grupo"
    
    echo "Usuario $nombre ahora pertenece a $nuevo_grupo."
}
