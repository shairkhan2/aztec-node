#!/bin/bash

# Exit immediately if any command fails
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

echo "Updating system packages..."
apt-get update
apt-get upgrade -y
apt install screen -y

echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "Installing Docker dependencies..."
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

echo "Setting up Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
> /etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y docker-ce
systemctl enable --now docker

echo "Installing Docker Compose..."
COMPOSE_VERSION=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" \
| grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Installing Aztec Network..."
yes y | bash -i <(curl -s https://install.aztec.network)
echo 'export PATH="$HOME/.aztec/bin:$PATH"' >> ~/.bashrc

# Screen session
echo "Creating and attaching to Aztec screen session..."
export PATH="$HOME/.aztec/bin:$PATH"
screen -S aztec -dm bash -c 'aztec-up 0.87.8 && echo -e "\nAztec services are install run finall cmd You can interact below. Use Ctrl+a d to detach." && exec bash'
screen -r aztec

echo "----------------------------------------------------------"
echo "Installation complete!"
echo "to start aztec just run your run cmd 'aztec'"
echo "Detach from screen session with: Ctrl+A then D"
echo "Reattach with: screen -r aztec"
echo "----------------------------------------------------------"


