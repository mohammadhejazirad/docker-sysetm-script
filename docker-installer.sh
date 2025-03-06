#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if script is running with sudo, if not, rerun with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Rerunning with sudo..."
    exec sudo "$0" "$@"
    exit $?
fi

# Function to check the OS type
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        echo "Detected OS: $OS $VER"
    else
        echo -e "${RED}Cannot detect OS. Exiting...${NC}"
        exit 1
    fi
}

# Function to check if Docker is installed
check_docker() {
    if command -v docker >/dev/null 2>&1; then
        DOCKER_VER=$(docker --version | awk '{print $3}' | sed 's/,//')
        echo "Docker is already installed. Version: $DOCKER_VER"
        return 0
    else
        echo "Docker is not installed."
        return 1
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        COMPOSE_VER=$(docker-compose --version | awk '{print $4}' | sed 's/,//')
        echo "Docker Compose is already installed. Version: $COMPOSE_VER"
        return 0
    else
        echo "Docker Compose is not installed."
        return 1
    fi
}

# Function to install Docker (official method)
install_docker() {
    echo "Installing Docker using the official method..."
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        apt-get update
        apt-get install -y ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
            tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        
        # Enable Docker to run without sudo
        echo "Adding current user to docker group to enable Docker without sudo..."
        usermod -aG docker $SUDO_USER
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Docker installed and configured successfully. Version: $(docker --version)${NC}"
            echo "Please log out and log back in to use Docker without sudo."
        else
            echo -e "${RED}Failed to add user to docker group.${NC}"
        fi
    else
        echo -e "${RED}This installation method is only supported on Ubuntu/Debian. Exiting...${NC}"
        exit 1
    fi
}

# Function to update Docker and Docker Compose
update_docker_and_compose() {
    echo "Checking for updates..."
    check_docker
    if [ $? -eq 0 ]; then
        echo "Updating Docker..."
        if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            apt-get update
            apt-get upgrade -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            echo -e "${GREEN}Docker updated successfully. New version: $(docker --version)${NC}"
        else
            echo -e "${RED}Update method only supported on Ubuntu/Debian.${NC}"
        fi
    else
        echo "Docker is not installed. Skipping Docker update."
    fi

    check_docker_compose
    if [ $? -eq 0 ]; then
        echo "Updating Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose updated successfully. New version: $(docker-compose --version)${NC}"
    else
        echo "Docker Compose is not installed. Skipping Docker Compose update."
    fi
}

# Function to install Docker Compose if not installed
install_docker_compose() {
    check_docker_compose
    if [ $? -eq 0 ]; then
        echo "Docker Compose is already installed with version $COMPOSE_VER."
        read -p "Do you want to update it? (y/n): " update_choice
        if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
            echo "Updating Docker Compose..."
            curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            echo -e "${GREEN}Docker Compose updated successfully. New version: $(docker-compose --version)${NC}"
        fi
    else
        echo "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose installed successfully. Version: $(docker-compose --version)${NC}"
    fi
}

# Main menu
while true; do
    echo "Docker Installation Script"
    echo "1- Install Docker"
    echo "2- Update Docker and Docker Compose"
    echo "3- Install Docker Compose"
    echo "0- Exit"
    read -p "Please select an option: " choice

    case $choice in
        1)
            check_os
            if ! check_docker; then
                install_docker
            else
                echo "Docker is already installed with version $DOCKER_VER. Use option 2 to update."
            fi
            ;;
        2)
            check_os
            update_docker_and_compose
            ;;
        3)
            check_os
            install_docker_compose
            ;;
        0)
            echo "Exiting script..."
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done