#!/usr/bin/env bash
# -----------------------------------------------------
# Script Name:    install_py.sh
# Version:        1.25.6
# Author:         Yaniv Mendiuk & Feigelman Evgeny
# Date:           2025-02-12
# Description:    This script will install all prerequesites and create a forlders for
#                 python application 
#      
set -o errexit 
set -o pipefail
set -x 
set -o nounset

# Define variables
PROJECT_NAME=""
WORK_DIR=""
LOG_FILE="/tmp/application_template_script_`date +"%Y%m%d-%H%M"`.log"

function check_no_root() {
    if [[ $EUID -eq 0 ]] || [[ $UID -eq 0 ]]; then
        echo "Error: Do not use root user or sudo to run this script"
        exit 1
    else
        # Check if we can use sudo
        if ! command -v sudo &> /dev/null; then
            echo "Error: sudo is required but not installed"
            exit 1
        fi
        sudo -v
    fi
}

function detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        echo "Error: /etc/os-release not found. Cannot detect operating system."
        exit 1
    else
        . /etc/os-release
        # First try with ID_LIKE, fallback to ID if ID_LIKE is not available
        if [[ -n "${ID_LIKE:-}" ]]; then
            whichOS=$(echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]')
        else
            whichOS=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        fi
        echo "Detected OS: $whichOS"
    fi
}

function install_debian() {
    echo "Installing packages for $whichOS OS."
    sudo apt update -y >> $LOG_FILE 2>&1
    sudo apt upgrade -y >> $LOG_FILE 2>&1
    if ! sudo apt install -y python3 python3-pip pipx pipenv python3-venv makeself sqlite3 >> $LOG_FILE 2>&1; then
        echo "Error: Failed to install Debian packages"
        exit 1
    fi
}

function install_rhel() {
    echo "Installing packages for $whichOS OS."
    if ! sudo dnf update -y >> $LOG_FILE 2>&1; then
        echo "Error: Failed to update package list"
        exit 1
    fi
    
    # Check if EPEL is already installed
    if ! rpm -q epel-release >> $LOG_FILE 2>&1; then
        echo "Installing EPEL repository..."
        if ! sudo dnf install -y epel-release >> $LOG_FILE 2>&1; then
            echo "Trying alternative EPEL installation method..."
            RHEL_VERSION=$(rpm -E '%{rhel}')
            if ! sudo dnf install -y "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${RHEL_VERSION}.noarch.rpm" >> $LOG_FILE 2>&1; then
                echo "Error: Failed to install EPEL repository"
                exit 1
            fi
        fi
    fi
    
    if ! sudo dnf update -y >> $LOG_FILE 2>&1; then
        echo "Error: Failed to update packages after EPEL installation"
        exit 1
    fi
    
    if ! sudo dnf install -y python39 python39-pip python39-devel git >> $LOG_FILE 2>&1; then
        echo "Error: Failed to install RHEL packages"
        exit 1
    fi
}

create_project_dir() {
    while [[ -z "$PROJECT_NAME" ]]; do
        read -p "What is the name of your project: " PROJECT_NAME
        if [[ -z "$PROJECT_NAME" ]]; then
            echo "Project name cannot be empty. Please try again."
        fi
    done
    
    WORK_DIR="$HOME/projects/$PROJECT_NAME"
    if [[ ! -d "$WORK_DIR" ]]; then 
        echo "Creating project directory at $WORK_DIR"
        mkdir -p "$WORK_DIR"
        cd "$WORK_DIR" || exit 1
        git init >> $LOG_FILE 2>&1
        touch .gitignore README.md TASKS.md CONTRIBUTORS.md LICENSE.md >> $LOG_FILE 2>&1
        mkdir -p "src/$PROJECT_NAME"/{libs,static,templates}
    else
        echo "$WORK_DIR already exists"
        cd "$WORK_DIR" || exit 1
    fi
}

install_debian_virtual_environment() {
    echo "Setting up Python virtual environment for Debian-based system"
    cd "$WORK_DIR" || exit 1
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"  # Apply to current script
    
    if ! pipenv install flask flask-sqlalchemy bootstrap-flask quart >> $LOG_FILE 2>&1; then
        echo "Error: Failed to install Python packages"
        exit 1
    fi
    
    echo "Python virtual environment setup complete"
}

install_rhel_virtual_environment() {
    echo "Setting up Python virtual environment for RHEL-based system"
    cd "$WORK_DIR" || exit 1
    
    if ! python3.9 -m pip install --user pipenv >> $LOG_FILE 2>&1; then
        echo "Error: Failed to install pipenv"
        exit 1
    fi
    
    if ! pipenv --python 3.9; then
        echo "Error: Failed to create Python virtual environment"
        exit 1
    fi
    
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"  # Apply to current script
    
    if ! pipenv install flask flask-sqlalchemy bootstrap-flask quart >> $LOG_FILE 2>&1; then
        echo "Error: Failed to install Python packages"
        exit 1
    fi
    
    echo "Python virtual environment setup complete"
}

main() {
    echo "Starting installation process..."
    check_no_root
    detect_os
    
    case $whichOS in
        *debian*|*ubuntu*) 
            install_debian 
            ;;
        *fedora*|*rhel*|*centos*) 
            install_rhel 
            ;;
        *) 
            echo "Error: $whichOS is not supported" 
            exit 1 
            ;;
    esac
    
    create_project_dir
    
    case $whichOS in
        *debian*|*ubuntu*) 
            install_debian_virtual_environment 
            ;;
        *fedora*|*rhel*|*centos*) 
            install_rhel_virtual_environment 
            ;;
        *) 
            echo "Error: $whichOS is not supported" 
            exit 1 
            ;;
    esac
    
    echo "Setup completed successfully!"
    echo "You can now activate your virtual environment with: cd $WORK_DIR && pipenv shell"
}

#################
#      MAIN     #
#################
main    