#!/usr/bin/env bash

# Proxmox LXC Creation Script for Standard Notes
# Author: [Tu Nombre o Usuario de GitHub]
# License: MIT
# Source: https://github.com/bitmodular/Proxmox-Scripts

set -e

# Variables
CTID=250
CT_NAME="standardnotes"
TEMPLATE="local:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
STORAGE="local-lvm"
DISK_SIZE="4G"
MEMORY="512"
CPUS="1"
NET="name=eth0,bridge=vmbr0,ip=dhcp"

# Función para mostrar mensajes de información
msg_info() {
  echo -e "\e[34m[INFO]\e[0m $1"
}

# Función para mostrar mensajes de éxito
msg_ok() {
  echo -e "\e[32m[OK]\e[0m $1"
}

# Función para mostrar mensajes de error
msg_error() {
  echo -e "\e[31m[ERROR]\e[0m $1"
}

msg_info "Creando el contenedor LXC con ID $CTID y nombre $CT_NAME..."
pct create $CTID $TEMPLATE -storage $STORAGE -rootfs $DISK_SIZE -memory $MEMORY -cores $CPUS -net0 $NET -hostname $CT_NAME --unprivileged 1 --features nesting=1

msg_info "Iniciando el contenedor..."
pct start $CTID

msg_info "Esperando a que el contenedor inicie completamente..."
sleep 10

msg_info "Descargando el script de instalación de Standard Notes en el contenedor..."
pct exec $CTID -- bash -c "curl -fsSL https://raw.githubusercontent.com/bitmodular/Proxmox-Scripts/main/ct/standardnotes.sh -o /root/standardnotes.sh"

msg_info "Asignando permisos de ejecución al script..."
pct exec $CTID -- chmod +x /root/standardnotes.sh

msg_info "Ejecutando el script de instalación dentro del contenedor..."
pct exec $CTID -- bash /root/standardnotes.sh

msg_ok "Contenedor creado e instalación de Standard Notes completada."
