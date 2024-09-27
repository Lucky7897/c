#!/bin/bash

# Update package list and install necessary tools
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils android-tools-adb wget

# Define variables
ISO_URL="https://www.fosshub.com/Android-x86.html?dwl=android-x86_64-9.0-r2.iso"
ISO_FILE="android-x86_64-9.0-r2.iso"
DISK_IMAGE="android.img"
DISK_SIZE="75G"
MEMORY="4096"
CPU="1"

# Download the Android-x86 ISO
wget -O $ISO_FILE $ISO_URL

# Create a disk image for Android-x86
qemu-img create -f qcow2 $DISK_IMAGE $DISK_SIZE

# Start the QEMU VM for installation
echo "Starting QEMU for Android-x86 installation. Follow the on-screen instructions to install Android-x86."
qemu-system-x86_64 -enable-kvm -m $MEMORY -smp $CPU -hda $DISK_IMAGE -cdrom $ISO_FILE -boot d -vga std -usb -device usb-tablet

# Wait for the user to complete the installation and reboot the VM
read -p "Press Enter after the installation is complete and the VM has rebooted."

# Start the QEMU VM with port redirection for ADB
echo "Starting QEMU with port redirection for ADB."
qemu-system-x86_64 -enable-kvm -m $MEMORY -smp $CPU -hda $DISK_IMAGE -vga std -usb -device usb-tablet -redir tcp:5555::5555 &

# Wait for the VM to boot
sleep 60

# Connect via ADB
adb connect localhost:5555

# Enable root access
adb root

# Download and install VNC server APK
VNC_APK="droidVNC-NG-1.2.0.apk"
wget https://github.com/bk138/droidVNC-NG/releases/download/v1.2.0/$VNC_APK
adb install $VNC_APK

# Start VNC server
adb shell am start -n com.bk138.droidvncng/.DroidVNC

echo "Android-x86 is now installed and configured with ADB and VNC for remote access."
echo "Use a VNC client to connect to the VNC server running on your server."
