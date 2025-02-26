#!/bin/bash

# Función para validar una dirección IP
ValidarIP() {
    local ip_address=$1
    local valid_format="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

    if [[ $ip_address =~ $valid_format ]]; then
        return 0
    else
        return 1
    fi
}