#!/bin/bash

# Check if the script is running with sudo, if not, prompt for it
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please enter your sudo password."
    exec sudo "$0" "$@"
    exit $?
fi

# Function to display colored text
echo_green() {
    echo -e "\e[1;32m$1\e[0m"
}
echo_red() {
    echo -e "\e[1;31m$1\e[0m"
}

# Function to display the menu
show_menu() {
    echo "Docker Mirror Configuration Script"
    echo "----------------------------------"
    echo_green "1. Enable IranServer Mirror (best)"
    echo "2. Enable ManageIT Mirror"
    echo "3. Enable ArvanCloud Mirror"
    echo "4. Enable Docker Iran Mirror"
    echo "5. Disable Mirror"
    echo "6. Test Mirror Connection"
    echo "0. Exit"
    echo "----------------------------------"
    echo -n "Please select an option (0-6): "
}

# Function to set a mirror in daemon.json
set_mirror() {
    DAEMON_FILE="/etc/docker/daemon.json"
    MIRROR_URL="$1"
    
    # Check if the file exists, if not, create it
    if [ ! -f "$DAEMON_FILE" ]; then
        echo "Creating $DAEMON_FILE..."
        mkdir -p /etc/docker
        touch "$DAEMON_FILE"
    fi
    
    # Write the mirror configuration
    echo "Enabling $2 mirror..."
    cat > "$DAEMON_FILE" << EOL
{
    "registry-mirrors": ["$MIRROR_URL"]
}
EOL
    
    # Restart Docker service to apply changes
    echo "Restarting Docker service..."
    systemctl daemon-reload
    systemctl restart docker
    
    echo_green "$2 mirror enabled successfully!"
}

# Function to disable the mirror
disable_mirror() {
    DAEMON_FILE="/etc/docker/daemon.json"
    
    if [ -f "$DAEMON_FILE" ]; then
        echo "Disabling mirror..."
        echo "{}" > "$DAEMON_FILE"
        
        # Restart Docker service
        echo "Restarting Docker service..."
        systemctl daemon-reload
        systemctl restart docker
        
        echo_green "Mirror disabled successfully!"
    else
        echo "No mirror configuration found to disable."
    fi
}

# Function to test mirror connection
test_mirror() {
    echo "Testing mirror connection..."
    # Try pulling a small image (hello-world) to test the mirror
    if docker pull hello-world >/dev/null 2>&1; then
        echo_green "Mirror connection test successful! Pulled 'hello-world' image."
        # Clean up by removing the test image
        docker rmi hello-world >/dev/null 2>&1
    else
        echo_red "Mirror connection test failed! Check your mirror settings or network."
        return 1
    fi
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            set_mirror "https://docker.iranserver.com" "IranServer"
            echo ""
            ;;
        2)
            set_mirror "https://docker.manageit.ir" "ManageIT"
            echo ""
            ;;
        3)
            set_mirror "https://mirror.arvancloud.ir/docker" "ArvanCloud"
            echo ""
            ;;
        4)
            set_mirror "https://docker.host:5000" "Docker Iran"
            echo ""
            ;;
        5)
            disable_mirror
            echo ""
            ;;
        6)
            test_mirror
            echo ""
            ;;
        0)
            echo "Exiting script. Goodbye!"
            exit 0
            ;;
        *)
            echo_red "Invalid option! Please select 0-6."
            echo ""
            ;;
    esac
done
