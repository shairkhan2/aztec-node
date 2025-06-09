#!/bin/bash

# Exit immediately if any command fails
set -e

# Check for sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo privileges"
    exit 1
fi

# Update and upgrade system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install Node.js
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get update
apt-get install -y nodejs

# Install Docker dependencies
echo "Installing Docker dependencies..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Add Docker repository and install
echo "Setting up Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce
systemctl enable --now docker

# Install Docker Compose
echo "Installing Docker Compose..."
COMPOSE_VERSION=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Aztec
echo "Installing Aztec Network..."
sudo -u $SUDO_USER bash -c 'yes y | head -n 2 | bash -i <(curl -s https://install.aztec.network)'
sudo -u $SUDO_USER bash -c 'echo "export PATH=\"\$HOME/.aztec/bin:\$PATH\"" >> ~/.bashrc'

# Add user to docker group
usermod -aG docker $SUDO_USER

# Create and open screen session
echo "Creating and attaching to Aztec screen session..."
bash -c 'source ~/.bashrc && screen -S aztec -dm bash -c "aztec-up alpha-testnet && aztec-up 0.87.7 && echo -e \"\nAztec services are running. You can interact below. Use Ctrl+a d to detach.\" && exec bash"'
screen -r aztec



echo "----------------------------------------------------------"
echo "Installation complete!"
echo "Aztec is running in screen session 'aztec'"
echo "Detach from screen session with: Ctrl+A then D"
echo "Reattach with: screen -r aztec"
echo "----------------------------------------------------------"
