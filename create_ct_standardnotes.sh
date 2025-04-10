#!/usr/bin/env bash

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

# Función para obtener el ID más bajo disponible para un contenedor LXC
get_next_container_id() {
  # Obtener la lista de contenedores existentes y filtrar los IDs
  local used_ids
  used_ids=$(pct list | awk '{print $1}' | tail -n +2)  # Obtener todos los IDs en uso
  local next_id=100  # Comenzar con el ID mínimo disponible (ajustable según tu configuración)

  # Buscar el primer ID libre
  while echo "$used_ids" | grep -qw "$next_id"; do
    next_id=$((next_id + 1))  # Incrementar el ID hasta encontrar uno libre
  done

  echo "$next_id"
}

# Obtener el próximo ID de contenedor disponible
CT_ID=$(get_next_container_id)
CT_NAME="standardnotes"

# Ajuste del tamaño del disco
DISK_SIZE="8G"  # Tamaño del disco, puedes ajustarlo

# Verificar si el contenedor ya existe
if pct list | grep -qw "$CT_ID"; then
  msg_error "El contenedor LXC con ID $CT_ID ya existe. Intentando usar otro ID."
  CT_ID=$(get_next_container_id)
fi

# Crear el contenedor LXC con el ID dinámico
msg_info "Creando el contenedor LXC con ID $CT_ID y nombre $CT_NAME..."

pct create $CT_ID /var/lib/vz/template/cache/debian-10-standard_10.7-1_amd64.tar.gz \
    -hostname $CT_NAME \
    -memory 2048 \
    -swap 512 \
    -cores 2 \
    -net0 name=eth0,bridge=vmbr0,ip=dhcp \
    -rootfs local-lvm:$DISK_SIZE  # Ajuste para el tamaño del disco

if [ $? -eq 0 ]; then
  msg_ok "Contenedor LXC $CT_ID creado correctamente."
else
  msg_error "Hubo un problema al crear el contenedor LXC."
  exit 1
fi

# Configuración posterior para instalar Standard Notes en el contenedor
msg_info "Configurando Standard Notes en el contenedor..."
pct exec $CT_ID -- bash -c "$(curl -fsSL https://raw.githubusercontent.com/bitmodular/Proxmox-Scripts/main/install_standardnotes.sh)"
msg_ok "Standard Notes instalado correctamente en el contenedor $CT_ID."
