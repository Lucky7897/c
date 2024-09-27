import os
import subprocess
import requests
import time

# Constants
ISO_URL = "https://osdn.net/projects/android-x86/releases/download/69249/android-x86_64-9.0-r2.iso"
ISO_FILE = "/tmp/android-x86_64-9.0-r2.iso"
FALLBACK_ISO_URLS = [
    "https://mirror.example.com/android-x86_64-9.0-r2.iso",
    "https://anothermirror.example.com/android-x86_64-9.0-r2.iso",
    "https://yetanothermirror.example.com/android-x86_64-9.0-r2.iso"
]
DISK_IMAGE = "/tmp/android.img"
DISK_SIZE = "75G"
MEMORY = "4096"  # Default memory allocation
CPU = "1"  # Default CPU allocation
VNC_APK = "droidVNC-NG-1.2.0.apk"
VNC_APK_URL = "https://github.com/bk138/droidVNC-NG/releases/download/v1.2.0/" + VNC_APK

def run_command(command):
    """Run a shell command and return the output."""
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.stdout.decode().strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{command}': {e.stderr.decode().strip()}")
        return None

def check_internet():
    """Check internet connectivity."""
    try:
        response = requests.get("https://www.google.com", timeout=5)
        return response.status_code == 200
    except requests.ConnectionError:
        return False

def download_file(url, destination):
    """Download a file from the given URL."""
    try:
        print(f"Downloading {url}...")
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(destination, 'wb') as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        print(f"Downloaded to {destination}")
        return True
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        return False

def get_system_memory():
    """Get the available system memory in MB."""
    mem_info = run_command("free -m")
    if mem_info:
        lines = mem_info.splitlines()
        total_memory = int(lines[1].split()[1])
        return total_memory
    return 0

def install_waydroid():
    """Install Waydroid."""
    run_command("sudo add-apt-repository -y ppa:waydroid/stable")
    run_command("sudo apt update")
    run_command("sudo apt install -y waydroid")
    run_command("waydroid init")
    run_command("waydroid session start")
    run_command(f"adb install /tmp/{VNC_APK}")

def install_anbox():
    """Install Anbox."""
    run_command("sudo add-apt-repository -y ppa:morphis/anbox-support")
    run_command("sudo apt update")
    run_command("sudo apt install -y anbox")
    run_command("anbox system-info")
    run_command(f"adb install /tmp/{VNC_APK}")

def install_android_x86():
    """Install Android-x86."""
    if not check_internet():
        print("No internet connection. Please ensure you are connected.")
        return

    if not download_file(ISO_URL, ISO_FILE):
        for url in FALLBACK_ISO_URLS:
            if download_file(url, ISO_FILE):
                break
        else:
            print("All download attempts failed. Please download the ISO manually.")
            return

    run_command(f"qemu-img create -f qcow2 {DISK_IMAGE} {DISK_SIZE}")
    run_command(f"qemu-system-x86_64 -enable-kvm -m {MEMORY} -smp {CPU} -hda {DISK_IMAGE} -cdrom {ISO_FILE} -boot d -vga std -usb -device usb-tablet &")
    time.sleep(1200)  # Wait for user to install Android-x86 manually
    input("Press Enter after completing the Android-x86 installation and rebooting the VM.")
    run_command(f"qemu-system-x86_64 -enable-kvm -m {MEMORY} -smp {CPU} -hda {DISK_IMAGE} -vga std -usb -device usb-tablet -redir tcp:5555::5555 &")
    input("Wait for Android to boot and then connect with ADB. Press Enter when done.")
    run_command("adb connect localhost:5555")

def main():
    """Main function to determine the installation method based on system memory."""
    memory = get_system_memory()
    print(f"Total system memory: {memory} MB")

    if memory >= 8192:
        print("Installing Waydroid...")
        install_waydroid()
    elif memory >= 4096:
        print("Installing Anbox...")
        install_anbox()
    else:
        print("Installing Android-x86...")
        install_android_x86()

if __name__ == "__main__":
    main()
