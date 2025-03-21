#!/usr/bin/env bash
# -----------------------------------------------------
# Script Name:    my_script.sh
# Version:        1.24.5
# Author:         Feigelman Evgeny
# Date:           2025-02-12
# Description:    This script will install most of needed packages, that you will use
#                 during your dayly work as a DevOps expert. Fill free to tell me if 
#                 you think that this script can be improved.
set -o errexit 
set -o pipefail 
set -x 

PACKAGES =  ("python3" "python3-pip" "python3-pipx" "python3-venv"  "makeself" "sqlite3" "virtualbox") 

# Function to check for root privileges
check_no_root() {
    if [[ $EUID == "0" ]] || [[ $UID == "0" ]]; then
        echo "Do not use root user or sudo "
        exit 1
    else
        sudo -v
    fi

}

 function set_os_type() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu|linuxmint)
                OS_TYPE="Debian-based"
                ;;
            rhel|centos|fedora)
                OS_TYPE="RHEL-based"
                ;;
            *)
                OS_TYPE="Unknown"
                ;;
        esac
    else
        OS_TYPE="Unknown"
    fi
}

function install_packages(){
    case $OS_TYPE in 
        Debian-based)
	echo Installing pakages for $OS_TYPE OS.
	sudo apt update;sudo apt upgrade -y;sudo apt install -y "${PACKAGES[@]}"
	;;

	RHEL-based)
	sudo yum update -y;
	sudo yum install -y epel-release || sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E '%{rhel}').noarch.rpm;
	sudo yum update -y;
	sudo yum install -y  "${PACKAGES[@]}"
	echo Installing pakages for $OS_TYPE OS.
        ;;

        *)
        echo -n "$OS_TYPE is unknown, please install manually"
        ;;
    esac
}