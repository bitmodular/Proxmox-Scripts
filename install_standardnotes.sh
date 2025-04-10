#!/usr/bin/env bash

# Variables
STANDARD_NOTES_VERSION="v4.1.2"  # Versión de Standard Notes
DB_PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)  # Generación de contraseña segura

# Actualizar sistema e instalar dependencias
msg_info() { echo -e "\e[34m[INFO]\e[0m $1"; }
msg_ok() { echo -e "\e[32m[OK]\e[0m $1"; }

msg_info "Actualizando sistema e instalando dependencias..."
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release wget unzip

# Instalar Node.js
msg_info "Instalando Node.js..."
curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt install -y nodejs

# Instalar Redis y otros requisitos
msg_info "Instalando Redis..."
apt install -y redis-server

# Descargar e instalar Standard Notes
msg_info "Descargando Standard Notes..."
cd /opt
wget https://github.com/standardnotes/sn-server/releases/download/$STANDARD_NOTES_VERSION/standard-notes-server-$STANDARD_NOTES_VERSION.tar.gz
tar -xzf standard-notes-server-$STANDARD_NOTES_VERSION.tar.gz
cd standard-notes-server-$STANDARD_NOTES_VERSION

# Crear archivo de configuración
cat <<EOF > .env
DATABASE_URL=postgres://standardnotes_user:$DB_PASSWORD@localhost:5432/standardnotes_db
APP_SECRET=$(openssl rand -base64 32)
EOF

# Instalar dependencias de Standard Notes
npm install

# Ejecutar migraciones y construir la aplicación
msg_info "Ejecutando migraciones..."
npm run migrate
msg_info "Construyendo la aplicación..."
npm run build

# Iniciar Standard Notes
msg_info "Iniciando Standard Notes..."
npm start &

msg_ok "Standard Notes instalado y ejecutándose correctamente."
