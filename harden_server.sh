#!/bin/bash

# --- Server Hardening Script ---
# This script automates essential security hardening steps for a Linux server.

echo "Starting server hardening process..."

# 1. Update System
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y
sudo apt autoremove -y

# 2. User Management
echo "Creating a new non-root user and configuring SSH access..."

read -p "Enter desired username for the new non-root user: " NEW_USER
read -p "Enter desired SSH public key for $NEW_USER (paste here or provide path to .pub file): " SSH_PUB_KEY

# Check if user already exists
if id "$NEW_USER" &>/dev/null; then
    echo "User $NEW_USER already exists."
else
    sudo adduser --gecos "" "$NEW_USER"
    sudo usermod -aG sudo "$NEW_USER"
    echo "User $NEW_USER created and added to sudo group."
fi

# Configure SSH for the new user
HOME_DIR=$(eval echo "~$NEW_USER")
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

sudo mkdir -p "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
echo "$SSH_PUB_KEY" | sudo tee -a "$AUTH_KEYS" > /dev/null
sudo chmod 600 "$AUTH_KEYS"
sudo chown -R "$NEW_USER:$NEW_USER" "$SSH_DIR"
echo "SSH key added for $NEW_USER."

# Disable root login via SSH
echo "Disabling root SSH login..."
sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# 3. SSH Hardening
echo "Hardening SSH configuration..."

# Disable password authentication
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Change default SSH port (e.g., to 2222 - user input recommended)
read -p "Enter desired SSH port (default is 22, recommend changing to a non-standard port): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}
sudo sed -i "s/^#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sudo sed -i "s/^Port [0-9]*/Port $SSH_PORT/" /etc/ssh/sshd_config

# Limit SSH users (allow only the new user)
echo "AllowUsers $NEW_USER" | sudo tee -a /etc/ssh/sshd_config > /dev/null

sudo systemctl reload sshd

# 4. Firewall Configuration (UFW)
echo "Configuring UFW firewall..."
sudo apt install ufw -y

# Deny all incoming by default, allow all outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH on the chosen port
sudo ufw allow "$SSH_PORT"/tcp

# Allow HTTP/S
sudo ufw allow http
sudo ufw allow https

# Enable UFW
echo "Enabling UFW. Confirm with 'y' if prompted."
sudo ufw enable

# 5. Fail2Ban Installation
echo "Installing Fail2Ban..."
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 6. Automatic Updates
echo "Configuring automatic security updates..."
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "Server hardening complete. Please reboot your server for all changes to take effect."
echo "You should now connect via SSH using user '$NEW_USER' on port '$SSH_PORT' with your SSH key."
