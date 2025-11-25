#!/bin/bash
# Default Configuration Values
# These are the fallback values used if not specified in config files

# Hypervisor defaults
DEFAULT_HYPERVISOR="multipass"  # Can be: multipass, virtualbox, hyper-v, libvirt

# VM resources
DEFAULT_CPUS=2
DEFAULT_MEMORY="4G"
DEFAULT_DISK="15G"
DEFAULT_IMAGE="24.04"  # Ubuntu LTS version

# VM networking
DEFAULT_NETWORK_MODE="automatic"  # For VirtualBox: NAT, host-only, internal, bridge

# VM naming and paths
DEFAULT_VM_PATH="/var/lib/virtualbox"  # VirtualBox VM path
DEFAULT_MULTIPASS_PATH="$HOME/.local/share/multipass"  # Multipass path

# Shell configuration
DEFAULT_SHELL="zsh"
DEFAULT_ZSH_THEME="powerlevel10k"
INSTALL_OHMYZSH="yes"

# Development tools
DEFAULT_INSTALL_LAMP="yes"
DEFAULT_INSTALL_NODE="no"
DEFAULT_INSTALL_PYTHON="no"
DEFAULT_INSTALL_ANGULAR="no"
DEFAULT_INSTALL_REACT="no"

# Node.js version
NODE_LTS_VERSION="lts/*"  # Use latest LTS version

# Python version
PYTHON_VERSION="3.11"

# Git configuration
GIT_DEFAULT_BRANCH="main"

# Project paths
PROJECT_BASE_PATH="/home/ubuntu"
WEB_ROOT="/var/www"

# Database
DEFAULT_DB_ENGINE="mariadb"
DEFAULT_DB_ROOT_PASSWORD="root"

# SSH configuration
SSH_KEY_TYPE="ed25519"
SSH_KEY_PATH="$HOME/.ssh"
SSH_CONFIG_PATH="$HOME/.ssh/config"

# Auto-update settings
ENABLE_AUTO_UPDATE="yes"
AUTO_UPDATE_CHECK_INTERVAL=86400  # 24 hours in seconds
AUTO_UPDATE_BACKGROUND="yes"

# Environment defaults
DEFAULT_ENVIRONMENT="development"  # development, test, production

# Logging
LOG_DIR="$ROOT_DIR/logs"
LOG_LEVEL="info"  # debug, info, warning, error

# Backup settings
ENABLE_BACKUPS="yes"
BACKUP_DIR=".backups"
MAX_BACKUPS=10

# UI/UX settings
ENABLE_COLORS="yes"
VERBOSE="no"
DEBUG="no"

# Dry-run mode (testing without making changes)
DRY_RUN="no"

# Export all defaults
export DEFAULT_HYPERVISOR
export DEFAULT_CPUS
export DEFAULT_MEMORY
export DEFAULT_DISK
export DEFAULT_IMAGE
export DEFAULT_SHELL
export DEFAULT_ZSH_THEME
export INSTALL_OHMYZSH
export DEFAULT_INSTALL_LAMP
export DEFAULT_INSTALL_NODE
export DEFAULT_INSTALL_PYTHON
export DEFAULT_INSTALL_ANGULAR
export DEFAULT_INSTALL_REACT
export NODE_LTS_VERSION
export PYTHON_VERSION
export DEFAULT_DB_ENGINE
export SSH_KEY_TYPE
export SSH_KEY_PATH
export SSH_CONFIG_PATH
export ENABLE_AUTO_UPDATE
export AUTO_UPDATE_CHECK_INTERVAL
export AUTO_UPDATE_BACKGROUND
export DEFAULT_ENVIRONMENT
export LOG_DIR
export LOG_LEVEL
export ENABLE_BACKUPS
export BACKUP_DIR
export MAX_BACKUPS
export ENABLE_COLORS
export VERBOSE
export DEBUG
export DRY_RUN
