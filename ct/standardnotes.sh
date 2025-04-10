#!/usr/bin/env bash

# Standard Notes Installation Script for Proxmox LXC
# Author: [Tu Nombre o Usuario de GitHub]
# License: MIT
# Source: https://github.com/bitmodular/Proxmox-Scripts

set -e

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

msg_info "Actualizando el sistema y instalando dependencias..."
apt-get update
apt-get upgrade -y
apt-get install -y curl wget sudo gnupg

msg_info "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

msg_info "Instalando PostgreSQL..."
apt-get install -y postgresql postgresql-contrib

msg_info "Generando una contraseña segura para la base de datos..."
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)

msg_info "Configurando PostgreSQL para Standard Notes..."
sudo -u postgres psql <<EOF
CREATE DATABASE standardnotes;
CREATE USER snuser WITH ENCRYPTED PASSWORD '$DB_PASS';
GRANT ALL PRIVILEGES ON DATABASE standardnotes TO snuser;
EOF

msg_info "Clonando el repositorio de Standard Notes..."
git clone https://github.com/standardnotes/server.git /opt/standardnotes

msg_info "Instalando dependencias de Standard Notes..."
cd /opt/standardnotes
npm install

msg_info "Configurando variables de entorno..."
cat <<EOF > /opt/standardnotes/.env
NODE_ENV=production
DB_CONNECTION=pg
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=standardnotes
DB_USERNAME=snuser
DB_PASSWORD=$DB_PASS
EOF

msg_info "Ejecutando migraciones y sembrando la base de datos..."
npm run migrate
npm run seed

msg_info "Creando servicio systemd para Standard Notes..."
cat <<EOF > /etc/systemd/system/standardnotes.service
[Unit]
Description=Standard Notes Service
After=network.target postgresql.service

[Service]
WorkingDirectory=/opt/standardnotes
ExecStart=/usr/bin/npm start
Restart=always
User=root
Environment=NODE_ENV=production
Environment=DB_CONNECTION=pg
Environment=DB_HOST=localhost
Environment=
