#!/bin/bash
# Zsh Installer
# Installs Zsh shell and sets it as default shell

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Install Zsh
install_zsh() {
    print_section "Installing Zsh shell"

    # Check if running as root or with sudo
    if ! is_root && ! has_sudo; then
        print_error "Zsh installation requires sudo privileges"
        return 1
    fi

    local sudo_cmd=""
    if ! is_root; then
        sudo_cmd="sudo"
    fi

    # Check if zsh is already installed
    if command_exists zsh; then
        local current_version
        current_version=$(zsh --version)
        print_info "Zsh already installed: $current_version"
        return 0
    fi

    # Update package list
    print_info "Updating package list..."
    if ! $sudo_cmd apt-get update 2>/dev/null; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install zsh
    print_info "Installing zsh..."
    if ! $sudo_cmd apt-get install -y zsh 2>/dev/null; then
        print_error "Failed to install zsh"
        return 1
    fi

    # Verify installation
    if ! command_exists zsh; then
        print_error "Zsh installation failed"
        return 1
    fi

    local zsh_version
    zsh_version=$(zsh --version)
    print_ok "Zsh installed: $zsh_version"

    print_ok "Zsh installation complete"
    echo ""

    return 0
}

# Set zsh as default shell
set_zsh_default() {
    local username=${1:-$(whoami)}

    if ! command_exists zsh; then
        print_error "Zsh is not installed"
        return 1
    fi

    local zsh_path
    zsh_path=$(command -v zsh)

    print_info "Setting Zsh as default shell for $username..."

    # Check if we need sudo
    if [[ "$username" != "$(whoami)" ]] && ! is_root; then
        sudo chsh -s "$zsh_path" "$username" 2>/dev/null || {
            print_warning "Could not set default shell. You may need to run: chsh -s $zsh_path"
            return 1
        }
    else
        chsh -s "$zsh_path" "$username" 2>/dev/null || {
            print_warning "Could not set default shell. You may need to run: chsh -s $zsh_path"
            return 1
        }
    fi

    print_ok "Zsh set as default shell for $username"
    return 0
}

# Get zsh installation status
get_zsh_status() {
    if command_exists zsh; then
        zsh --version
    else
        echo "not-installed"
    fi
}

# Verify zsh installation
verify_zsh() {
    print_section "Verifying Zsh Installation"

    if command_exists zsh; then
        local zsh_version
        zsh_version=$(zsh --version)
        print_ok "Zsh: $zsh_version"
        echo ""
        print_ok "Zsh is installed"
        return 0
    else
        print_warning "Zsh not found"
        echo ""
        return 1
    fi
}

# Export functions
export -f install_zsh
export -f set_zsh_default
export -f get_zsh_status
export -f verify_zsh
