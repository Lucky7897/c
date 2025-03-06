#!/bin/bash

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  log "Please run as root"
  exit 1
fi

# Function to backup a file
backup_file() {
  local file=$1
  if [ -f "$file" ]; then
    cp "$file" "$file.bak"
    log "Backup of $file created"
  fi
}

# Function to remove key references
remove_key_references() {
  local dir=$1
  find "$dir" -type f -exec sed -i '/^AuthorizedKeysFile/d' {} \;
  log "Removed key references in $dir"
}

# Function to create a new SSH config file
create_sshd_config() {
  cat <<EOL > /etc/ssh/sshd_config
# SSH configuration file
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOL
  log "New SSH config file created"
}

# Ensure SSH server is installed
apt update && apt install -y openssh-server

# Backup existing SSH config file
backup_file "/etc/ssh/sshd_config"

# Remove key references in SSH directory
remove_key_references "/etc/ssh"

# Create a new SSH config file
create_sshd_config

# Restart the SSH service to apply changes
if systemctl restart ssh; then
  log "SSH service restarted successfully"
else
  log "Failed to restart SSH service, reverting to backup"
  cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
  systemctl restart ssh && log "Reverted to backup and restarted SSH service"
fi

log "SSH configuration has been reset and updated."