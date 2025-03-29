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

WORK_DIR="$HOME/projects/$PROJECT_NAME"
PROJECT_NAME=""


check_no_root() {
    if [[ $EUID == "0" ]] || [[ $UID == "0" ]]; then
        echo "Do not use root user or sudo "
        exit 1
    else
        sudo -v
    fi

}

# Checking which OS

if [[ ! -f /etc/os-release ]]; then
    echo "Error: /etc/os-release not found. Cannot detect operating system."
    exit 1
else
    . /etc/os-release
    whichOS=$(echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]')
    echo "Detected OS: $whichOS"
fi



function install_debian(){
	echo Installing pakages for $whichOS OS.
	sudo apt update;sudo apt upgrade -y;sudo apt install -y python3 python3-pip pipx python3-venv makeself sqlite3
}
function install_rhel(){
	sudo dnf update -y;
	sudo dnf install -y epel-release || sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm;
	sudo dnf update -y;
	sudo dnf install -y  python3 python3-pip python3-virtualenv makeself sqlite
	echo Installing pakages for $whichOS OS.     
    
}

case $whichOS in
    *debian*) install_debian ;;
    *fedora*) install_rhel ;;
    *) echo "$whichOS is not supported" && exit 1 ;;
esac

# Function to read user's input to create a new project.

function create_project_dir(){
    read -p "What is the name of your project: " PROJECT_NAME
    WORK_DIR="$HOME/projects/$PROJECT_NAME"

    if [[ ! -d "$WORK_DIR" ]]; then 
        echo "$WORK_DIR does not exist"
        mkdir -p "$WORK_DIR"
    else
        echo "$WORK_DIR already exists"
    fi
}


create_project_dir