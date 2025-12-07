#!/bin/bash
set -euo pipefail

# ================================================================================
# Xubuntu Minimal Desktop + XFCE Enhancements Installation Script
# ================================================================================

# ================================================================================
# Step 1: Install Xubuntu minimal desktop environment
# ================================================================================

sudo apt-get update -y
sudo apt-get install -y xubuntu-desktop-minimal

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

# Backup original wallpaper for safety
sudo mv xfce-shapes.svg xfce-shapes.svg.bak

# Replace with an existing, stable wallpaper
sudo cp xfce-leaves.svg xfce-shapes.svg


# ================================================================================
# Completed
# ================================================================================

echo "NOTE: Xubuntu minimal desktop + Azure-safe networking configuration complete."
