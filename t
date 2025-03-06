#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Update package list and install openssh-server if not installed
apt update
apt install -y openssh-server

# Backup the current sshd_config file
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Configure SSH to use password authentication
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

# Restart the SSH service to apply changes
systemctl restart ssh

echo "SSH has been configured to use password-based authentication."

# Ensure the user has a password
echo "Please set a password for your user:"
passwd your_username