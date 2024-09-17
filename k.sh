#!/bin/bash

# Configuration
ISO_URL="http://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-live-amd64.iso"
ISO_PATH="/mnt/iso/kali-linux.iso"
MOUNT_POINT="/mnt/iso"
INSTALL_MOUNT="/mnt/install"
USER_NAME="kali"
USER_PASS="lollol"
ROOT_PASS="rootpassword"

# Update and install required tools
apt update
apt install -y wget mount debootstrap grub-pc

# Download Kali Linux ISO
mkdir -p $MOUNT_POINT
wget -O $ISO_PATH $ISO_URL

# Mount the ISO
mount -o loop $ISO_PATH $MOUNT_POINT

# Prepare the partition for Kali Linux installation
# This example assumes you are adding a new partition and keeping existing partitions intact.
# You will need to adjust partitioning commands based on your current disk layout.

echo "Creating new partition for Kali Linux..."
(
echo n  # New partition
echo p  # Primary partition
echo 2  # Partition number (adjust as needed)
echo    # Default first sector
echo    # Default last sector
echo w  # Write changes
) | fdisk /dev/sda

# Format the new partition
mkfs.ext4 /dev/sda2  # Adjust partition name as needed

# Mount the new partition
mkdir -p $INSTALL_MOUNT
mount /dev/sda2 $INSTALL_MOUNT

# Copy ISO contents to the new partition
cp -a $MOUNT_POINT/* $INSTALL_MOUNT

# Prepare for chroot
mount --bind /dev $INSTALL_MOUNT/dev
mount --bind /proc $INSTALL_MOUNT/proc
mount --bind /sys $INSTALL_MOUNT/sys

# Chroot into the new installation
chroot $INSTALL_MOUNT /bin/bash <<EOF
# Set root password
echo "root:$ROOT_PASS" | chpasswd

# Install Kali Linux packages
apt update
apt install -y kali-linux-full kali-linux-gnome-core

# Install and configure GRUB
grub-install /dev/sda
update-grub

# Add new user with password
useradd -m $USER_NAME
echo "$USER_NAME:$USER_PASS" | chpasswd

# Install and configure SSH server
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Install and configure GUI
apt install -y gnome-core

# Exit chroot
EOF

# Clean up
umount $INSTALL_MOUNT/dev
umount $INSTALL_MOUNT/proc
umount $INSTALL_MOUNT/sys
umount $INSTALL_MOUNT
umount $MOUNT_POINT

# Reboot into the new Kali installation
reboot
