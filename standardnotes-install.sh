#!/usr/bin/env bash

# ==============================================================================
# Standard Notes Sync Server Installer for Proxmox LXC
# Author: Bitmodular
# License: MIT
# Source: https://standardnotes.com
# ==============================================================================

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  gnupg \
  ca-certificates \
  apt-transport-https \
  lsb-release \
  docker.io \
  docker-compose
msg_ok "Installed Dependencies"

msg_info "Setting up Standard Notes Sync Server"
mkdir -p /opt/standard-notes
cd /opt/standard-notes

DB_USER="notes"
DB_NAME="notesdb"
DB_PASS="$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)"

curl -fsSL https://raw.githubusercontent.com/standardnotes/sync-server/main/docker-compose.yml -o docker-compose.yml

cat <<EOF >.env
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_DB=${DB_NAME}
EOF

$STD docker compose up -d
msg_ok "Set up Standard Notes Sync Server"

msg_info "Saving Credentials"
{
  echo "StandardNotes-Credentials"
  echo "Database Name: $DB_NAME"
  echo "Database User: $DB_USER"
  echo "Database Password: $DB_PASS"
} >> ~/standardnotes.creds
msg_ok "Saved Credentials"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
