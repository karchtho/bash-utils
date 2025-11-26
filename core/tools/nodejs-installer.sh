#!/bin/bash
# Node.js and npm LTS Installer
# Installs Node.js LTS version using NodeSource repository

# Source required libraries
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$PROJECT_ROOT/core/lib/colors.sh"
source "$PROJECT_ROOT/core/lib/error-handler.sh"
source "$PROJECT_ROOT/core/lib/validation.sh"
source "$PROJECT_ROOT/core/lib/common.sh"

# Default Node.js LTS version (major version number)
NODE_VERSION="${NODE_VERSION:-20}"

# Install Node.js LTS
install_nodejs() {
    local version=${1:-$NODE_VERSION}

    print_section "Installing Node.js LTS (v$version)"

    # Check if running as root or with sudo
    if ! is_root && ! has_sudo; then
        print_error "Node.js installation requires sudo privileges"
        return 1
    fi

    local sudo_cmd=""
    if ! is_root; then
        sudo_cmd="sudo"
    fi

    # Check if Node.js already installed
    if command_exists node; then
        local current_version
        current_version=$(node --version)
        print_info "Node.js already installed: $current_version"
        return 0
    fi

    # Update package list
    print_info "Updating package list..."
    if ! $sudo_cmd apt-get update 2>/dev/null; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install curl (needed for NodeSource setup)
    if ! command_exists curl; then
        print_info "Installing curl..."
        $sudo_cmd apt-get install -y curl 2>/dev/null || true
    fi

    # Add NodeSource repository
    print_info "Adding NodeSource repository for Node.js v$version..."
    if ! curl -fsSL "https://deb.nodesource.com/setup_${version}.x" 2>/dev/null | $sudo_cmd bash - 2>/dev/null; then
        print_error "Failed to add NodeSource repository"
        print_info "Attempting fallback installation from apt repositories..."
        if ! $sudo_cmd apt-get install -y nodejs npm 2>/dev/null; then
            print_error "Failed to install Node.js"
            return 1
        fi
    else
        # Install Node.js from NodeSource
        print_info "Installing Node.js from NodeSource repository..."
        if ! $sudo_cmd apt-get install -y nodejs 2>/dev/null; then
            print_error "Failed to install Node.js"
            return 1
        fi
    fi

    # Verify installation
    if ! command_exists node; then
        print_error "Node.js installation failed"
        return 1
    fi

    local node_version
    node_version=$(node --version)
    print_ok "Node.js installed: $node_version"

    # Verify npm
    if ! command_exists npm; then
        print_error "npm not found after Node.js installation"
        return 1
    fi

    local npm_version
    npm_version=$(npm --version)
    print_ok "npm installed: $npm_version"

    # Install global tools (optional)
    print_info "Installing global npm tools..."
    npm install -g npm@latest 2>/dev/null || true
    npm install -g yarn 2>/dev/null || true

    print_ok "Node.js and npm installation complete"
    echo ""

    return 0
}

# Get Node.js installation status
get_nodejs_status() {
    if command_exists node; then
        node --version
    else
        echo "not-installed"
    fi
}

# Verify Node.js installation
verify_nodejs() {
    print_section "Verifying Node.js Installation"

    local all_ok=true

    # Check Node.js
    if command_exists node; then
        local node_version
        node_version=$(node --version)
        print_ok "Node.js: $node_version"
    else
        print_warning "Node.js not found"
        all_ok=false
    fi

    # Check npm
    if command_exists npm; then
        local npm_version
        npm_version=$(npm --version)
        print_ok "npm: $npm_version"
    else
        print_warning "npm not found"
        all_ok=false
    fi

    # Check yarn (optional)
    if command_exists yarn; then
        local yarn_version
        yarn_version=$(yarn --version)
        print_ok "yarn: $yarn_version"
    fi

    echo ""

    if $all_ok; then
        print_ok "Node.js is fully installed"
        return 0
    else
        print_warning "Some Node.js components are missing"
        return 1
    fi
}

# Export functions
export -f install_nodejs
export -f get_nodejs_status
export -f verify_nodejs
