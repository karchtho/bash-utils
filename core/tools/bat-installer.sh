#!/bin/bash
# bat Installer
# Installs bat - a cat clone with syntax highlighting and Git integration

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Install bat
install_bat() {
    print_section "Installing bat (cat clone with syntax highlighting)"

    # Check if running as root or with sudo
    if ! is_root && ! has_sudo; then
        print_error "bat installation requires sudo privileges"
        return 1
    fi

    local sudo_cmd=""
    if ! is_root; then
        sudo_cmd="sudo"
    fi

    # Check if bat is already installed
    if command_exists bat; then
        local current_version
        current_version=$(bat --version)
        print_info "bat already installed: $current_version"
        return 0
    fi

    # Update package list
    print_info "Updating package list..."
    if ! $sudo_cmd apt-get update 2>/dev/null; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install bat
    print_info "Installing bat..."
    if ! $sudo_cmd apt-get install -y bat 2>/dev/null; then
        print_error "Failed to install bat"
        return 1
    fi

    # Verify installation
    if ! command_exists bat; then
        print_error "bat installation failed"
        return 1
    fi

    local bat_version
    bat_version=$(bat --version)
    print_ok "bat installed: $bat_version"

    # Create alias if needed (on some systems bat is installed as batcat)
    if command_exists batcat && ! command_exists bat; then
        print_info "Creating 'bat' alias for 'batcat'..."
        echo "  Tip: Add 'alias bat=batcat' to your shell profile if needed"
    fi

    print_ok "bat installation complete"
    echo ""

    return 0
}

# Get bat installation status
get_bat_status() {
    if command_exists bat; then
        bat --version
    elif command_exists batcat; then
        echo "batcat (aliased as bat)"
    else
        echo "not-installed"
    fi
}

# Verify bat installation
verify_bat() {
    print_section "Verifying bat Installation"

    local all_ok=true

    # Check bat
    if command_exists bat; then
        local bat_version
        bat_version=$(bat --version)
        print_ok "bat: $bat_version"
    elif command_exists batcat; then
        print_ok "batcat: installed (use as bat clone)"
    else
        print_warning "bat not found"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_ok "bat is installed"
        return 0
    else
        print_warning "bat is not installed"
        return 1
    fi
}

# Export functions
export -f install_bat
export -f get_bat_status
export -f verify_bat
