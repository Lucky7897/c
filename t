#!/bin/bash

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

if [ "$EUID" -ne 0 ]; then
  log "Please run as root"
  exit 1
fi

backup_file() {
  local file=$1
  if [ -f "$file" ]; then
    cp "$file" "$file.bak"
    log "Backup of $file created"
  fi
}

remove_key_references() {
  local dir=$1
  find "$dir" -type f -exec sed -i '/^AuthorizedKeysFile/d' {} \;
  log "Removed key references in $dir"
}

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

create_user() {
  local username=$1
  local password=$2
  if id "$username" &>/dev/null; then
    log "User $username already exists"
  else
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    log "User $username created"
  fi
}

apt update && apt install -y openssh-server

backup_file "/etc/ssh/sshd_config"
remove_key_references "/etc/ssh"
create_sshd_config

if systemctl restart ssh; then
  log "SSH service restarted successfully"
else
  log "Failed to restart SSH service, reverting to backup"
  cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
  systemctl restart ssh && log "Reverted to backup and restarted SSH service"
fi

# Create a user with a password
read -p "Enter the username for the new user: " username
read -sp "Enter the password for the new user: " password
echo
create_user "$username" "$password"

log "SSH configuration has been reset and updated."