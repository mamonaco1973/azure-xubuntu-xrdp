#!/bin/bash
set -euo pipefail

# ================================================================================
# Xubuntu Minimal Desktop + XFCE Enhancements Installation Script
# Azure-Safe Version (Prevents Networking Failure on Reboot)
# ================================================================================
# Description:
#   Installs Xubuntu minimal desktop environment and ensures the final Azure VM
#   uses systemd-networkd instead of NetworkManager. This prevents Azure reboot
#   issues where SSH/XRDP fail because NetworkManager overwrites netplan or
#   races cloud-init on boot.
# ================================================================================

# ================================================================================
# Step 1: Install Xubuntu minimal desktop environment
# ================================================================================
sudo apt-get update -y
sudo apt-get install -y xubuntu-desktop-minimal

# ================================================================================
# Step 1B: REMOVE NETWORKMANAGER (Critical for Azure Stability)
# ================================================================================
# NetworkManager gets reinstalled by the desktop packages — remove it now.
sudo apt-get remove --purge -y network-manager
sudo apt-get autoremove -y

# Prevent cloud-init or desktop packages from switching to NetworkManager again.
sudo mkdir -p /etc/cloud/cloud.cfg.d
echo "network: {config: disabled}" \
  | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# Provide a clean Azure-friendly netplan configuration.
sudo tee /etc/netplan/01-azure.yaml >/dev/null <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
EOF

sudo netplan generate

# ================================================================================
# Step 2: Install clipboard utilities and XFCE enhancements
# ================================================================================
sudo apt-get install -y \
  xfce4-clipman \
  xfce4-clipman-plugin \
  xsel \
  xclip

sudo apt-get install -y \
  xfce4-terminal \
  xfce4-goodies \
  xdg-utils

# ================================================================================
# Step 3: Set XFCE Terminal as the system-wide default terminal emulator
# ================================================================================
sudo update-alternatives --install \
  /usr/bin/x-terminal-emulator \
  x-terminal-emulator \
  /usr/bin/xfce4-terminal \
  50

# ================================================================================
# Step 4: Ensure new users receive a Desktop folder
# ================================================================================
sudo mkdir -p /etc/skel/Desktop

# ================================================================================
# Step 5: Replace default XFCE background image
# ================================================================================
cd /usr/share/backgrounds/xfce

# Backup the original wallpaper
sudo mv xfce-shapes.svg xfce-shapes.svg.bak

# Replace wallpaper with existing known-good asset
sudo cp xfce-leaves.svg xfce-shapes.svg

echo "NOTE: Xubuntu minimal desktop + Azure-safe networking configuration complete."
