#!/bin/bash
# Python with venv Installer
# Installs Python3 with virtual environment support

# Source required libraries
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$PROJECT_ROOT/core/lib/colors.sh"
source "$PROJECT_ROOT/core/lib/error-handler.sh"
source "$PROJECT_ROOT/core/lib/validation.sh"
source "$PROJECT_ROOT/core/lib/common.sh"

# Install Python with venv
install_python() {
    print_section "Installing Python3 with venv"

    # Check if running as root or with sudo
    if ! is_root && ! has_sudo; then
        print_error "Python installation requires sudo privileges"
        return 1
    fi

    local sudo_cmd=""
    [[ ! is_root ]] && sudo_cmd="sudo"

    # Check if Python already installed
    if command_exists python3; then
        local current_version
        current_version=$(python3 --version)
        print_info "Python3 already installed: $current_version"
    fi

    # Update package list
    print_info "Updating package list..."
    if ! $sudo_cmd apt-get update 2>/dev/null; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install Python3 and venv
    print_info "Installing Python3 and venv..."
    if ! $sudo_cmd apt-get install -y python3 python3-venv python3-pip 2>/dev/null; then
        print_error "Failed to install Python3"
        return 1
    fi

    # Install common Python development tools
    print_info "Installing Python development tools..."
    local dev_packages="python3-dev build-essential libssl-dev libffi-dev"
    $sudo_cmd apt-get install -y $dev_packages 2>/dev/null || true

    # Verify installation
    if ! command_exists python3; then
        print_error "Python3 installation failed"
        return 1
    fi

    local python_version
    python_version=$(python3 --version)
    print_ok "Python3 installed: $python_version"

    # Verify pip
    if ! command_exists pip3; then
        print_error "pip3 not found after Python3 installation"
        return 1
    fi

    local pip_version
    pip_version=$(pip3 --version)
    print_ok "pip3 installed: $pip_version"

    # Verify venv
    if ! python3 -m venv --help >/dev/null 2>&1; then
        print_error "venv module not available"
        return 1
    fi
    print_ok "Python venv module available"

    # Upgrade pip
    print_info "Upgrading pip..."
    pip3 install --upgrade pip 2>/dev/null || true

    # Install common packages
    print_info "Installing common Python packages..."
    pip3 install --upgrade setuptools wheel 2>/dev/null || true
    pip3 install python-dotenv requests flask django 2>/dev/null || true

    print_ok "Python3 with venv installation complete"
    echo ""

    return 0
}

# Create a Python virtual environment
create_python_venv() {
    local venv_path=${1:-.venv}
    local python_version=${2:-3}

    if [[ ! -d "$venv_path" ]]; then
        print_info "Creating Python virtual environment at: $venv_path"
        python$python_version -m venv "$venv_path" || return 1
        print_ok "Virtual environment created"
    else
        print_info "Virtual environment already exists at: $venv_path"
    fi

    return 0
}

# Activate Python virtual environment (note: must be sourced)
activate_python_venv() {
    local venv_path=${1:-.venv}

    if [[ ! -f "$venv_path/bin/activate" ]]; then
        print_error "Virtual environment not found at: $venv_path"
        return 1
    fi

    source "$venv_path/bin/activate"
    return 0
}

# Get Python installation status
get_python_status() {
    if command_exists python3; then
        python3 --version
    else
        echo "not-installed"
    fi
}

# Verify Python installation
verify_python() {
    print_section "Verifying Python Installation"

    local all_ok=true

    # Check Python3
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version)
        print_ok "Python3: $python_version"
    else
        print_warning "Python3 not found"
        all_ok=false
    fi

    # Check pip3
    if command_exists pip3; then
        local pip_version
        pip_version=$(pip3 --version)
        print_ok "pip3: $pip_version"
    else
        print_warning "pip3 not found"
        all_ok=false
    fi

    # Check venv
    if python3 -m venv --help >/dev/null 2>&1; then
        print_ok "venv: available"
    else
        print_warning "venv not available"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_ok "Python3 is fully installed"
        return 0
    else
        print_warning "Some Python components are missing"
        return 1
    fi
}

# Export functions
export -f install_python
export -f create_python_venv
export -f activate_python_venv
export -f get_python_status
export -f verify_python
