import json
import pathlib
import subprocess
import sys
import os

# List of supported Ubuntu versions
supported_versions = ['22.04', '24.04']

def check_root_privileges():
    """Check if the script is run with root privileges."""
    if os.geteuid() != 0:
        print("This script needs to be run with root privileges. Please run as root or use sudo.")
        sys.exit(1)

def check_ubuntu_version():
    """Check if the current Ubuntu version is supported."""
    try:
        result = subprocess.run(['lsb_release', '-r'], check=True, stdout=subprocess.PIPE)
        if not any(version in result.stdout.decode() for version in supported_versions):
            print(f"Your Ubuntu version is not supported. The following versions are supported: {supported_versions}")
            sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(f"Error checking Ubuntu version: {e}")
        sys.exit(1)

def update_docker_configuration():
    """Update Docker daemon configuration if necessary."""
    json_path = pathlib.Path("/etc/docker/daemon.json")
    if not json_path.is_file():
        print("Docker configuration file does not exist. Please run the vastai install script first.")
        sys.exit(1)

    with json_path.open('r', encoding='utf-8') as f:
        json_dict = json.load(f) or {}

    if 'exec-opts' not in json_dict:
        json_dict['exec-opts'] = ["native.cgroupdriver=cgroupfs"]
        with json_path.open('w', encoding='utf-8') as f:
            json.dump(json_dict, f, indent=4, sort_keys=True)
        print("Docker configuration updated.")
    else:
        print("Docker configuration already contains 'exec-opts'. No update needed.")

def blacklist_nouveau_driver():
    """Blacklist Nouveau driver and update initramfs."""
    blacklist_file = pathlib.Path("/etc/modprobe.d/blacklist-nvidia-nouveau.conf")
    if not blacklist_file.exists() or "nouveau" not in blacklist_file.read_text():
        with blacklist_file.open('w') as f:
            f.write("blacklist nouveau\n")
            f.write("options nouveau modeset=0\n")
        subprocess.run(['update-initramfs', '-u'], check=True)
        print("Nouveau driver blacklisted and initramfs updated.")
    else:
        print("Nouveau driver already blacklisted. No changes made.")

def update_grub_configuration():
    """Update GRUB configuration for cgroup hierarchy."""
    grub_file = pathlib.Path("/etc/default/grub.d/cgroup.cfg")
    grub_content = 'GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=false"'
    if not grub_file.exists() or grub_content not in grub_file.read_text():
        with grub_file.open('w') as f:
            f.write(grub_content + "\n")
        subprocess.run(['update-grub'], check=True)
        print("GRUB configuration updated.")
    else:
        print("GRUB configuration already set. No update needed.")

def main():
    """Main function to orchestrate the script operations."""
    check_root_privileges()
    check_ubuntu_version()
    update_docker_configuration()
    blacklist_nouveau_driver()
    update_grub_configuration()
    print("Complete. Run vastai install script again if necessary.")

if __name__ == "__main__":
    main()
