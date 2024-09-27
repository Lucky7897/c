import os
import subprocess
import requests
import time

# Constants
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
    print("Installing Waydroid...")
    run_command("sudo add-apt-repository -y ppa:waydroid/stable")
    run_command("sudo apt update")
    run_command("sudo apt install -y waydroid")
    run_command("waydroid init")
    run_command("waydroid session start")
    
    # Install VNC APK for Waydroid
    if download_file(VNC_APK_URL, f"/tmp/{VNC_APK}"):
        run_command(f"adb install /tmp/{VNC_APK}")
    else:
        print("Failed to download VNC APK for Waydroid.")

def install_anbox():
    """Install Anbox."""
    print("Installing Anbox...")
    run_command("sudo add-apt-repository -y ppa:morphis/anbox-support")
    run_command("sudo apt update")
    run_command("sudo apt install -y anbox")
    run_command("anbox system-info")

    # Install VNC APK for Anbox
    if download_file(VNC_APK_URL, f"/tmp/{VNC_APK}"):
        run_command(f"adb install /tmp/{VNC_APK}")
    else:
        print("Failed to download VNC APK for Anbox.")

def main():
    """Main function to handle installations."""
    if not check_internet():
        print("No internet connection. Please ensure you are connected.")
        return

    memory = get_system_memory()
    print(f"Total system memory: {memory} MB")

    # First, try to install Waydroid
    try:
        install_waydroid()
        print("Waydroid installed successfully.")
    except Exception as e:
        print(f"Waydroid installation failed: {e}")
        print("Attempting to install Anbox as a fallback...")
        install_anbox()

if __name__ == "__main__":
    main()
