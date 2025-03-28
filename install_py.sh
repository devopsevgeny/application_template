#!/usr/bin/env bash
# -----------------------------------------------------
# Script Name:    install_py.sh
# Version:        1.24.5
# Author:         Yaniv Mendiuk & Feigelman Evgeny
# Date:           2025-02-12
# Description:    This script will install most of needed packages, that you will use
#                 during your dayly work as a DevOps expert. Fill free to tell me if 
#                 you think that this script can be improved.
set -o errexit 
set -o pipefail 
set -x 

PACKAGES=("python3" "python3-pip" "pipx" "python3-venv"  "makeself" "sqlite3") 

# Function to check for root privileges
check_no_root() {
    if [[ $EUID == "0" ]] || [[ $UID == "0" ]]; then
        echo "Do not use root user or sudo "
        exit 1
    else
        sudo -v
    fi

}

# Checking which OS
whichOS=$(cat /etc/os-release | grep "ID_LIKE=" | sed 's/ID_LIKE=//')
echo "Detected OS: $whichOS"

function install_debian(){
	echo Installing pakages for $whichOS OS.
	sudo apt update;sudo apt upgrade -y;sudo apt install -y "${PACKAGES[@]}"
}
function install_rhel(){
	sudo dnf update -y;
	sudo dnf install -y epel-release || sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm;
	sudo dnf update -y;
	sudo dnf install -y  "${PACKAGES[@]}"
	echo Installing pakages for $whichOS OS.
    
        
    
}

case $whichOS in
    *debian*) install_debian ;;
    *fedora*) install_rhel ;;
    *) echo "$whichOS is not supported" && exit 1 ;;
esac