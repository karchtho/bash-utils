#!/bin/bash
# LAMP Stack Installer
# Installs Linux (Ubuntu), Apache2, MySQL, PHP
# Used both locally and in VMs

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Install LAMP stack
install_lamp() {
    print_section "Installing LAMP Stack"

    # Check if running as root or with sudo
    if ! is_root && ! has_sudo; then
        print_error "LAMP installation requires sudo privileges"
        return 1
    fi

    local sudo_cmd=""
    [[ ! is_root ]] && sudo_cmd="sudo"

    # Update package list
    print_info "Updating package list..."
    if ! $sudo_cmd apt-get update 2>/dev/null; then
        print_error "Failed to update package list"
        return 1
    fi

    # Install Apache2
    print_info "Installing Apache2..."
    if ! $sudo_cmd apt-get install -y apache2 2>/dev/null; then
        print_error "Failed to install Apache2"
        return 1
    fi
    print_ok "Apache2 installed"

    # Enable Apache modules
    print_info "Enabling Apache modules..."
    $sudo_cmd a2enmod rewrite 2>/dev/null || true
    $sudo_cmd a2enmod ssl 2>/dev/null || true

    # Install MySQL Server
    print_info "Installing MySQL Server..."
    if ! $sudo_cmd apt-get install -y mysql-server 2>/dev/null; then
        print_error "Failed to install MySQL Server"
        return 1
    fi
    print_ok "MySQL Server installed"

    # Install PHP and common extensions
    print_info "Installing PHP and extensions..."
    local php_packages="php php-apache2 php-mysql php-curl php-json php-mbstring php-xml php-zip"
    if ! $sudo_cmd apt-get install -y $php_packages 2>/dev/null; then
        print_error "Failed to install PHP"
        return 1
    fi
    print_ok "PHP installed"

    # Enable PHP module in Apache
    print_info "Enabling PHP module in Apache..."
    $sudo_cmd a2enmod php* 2>/dev/null || true

    # Restart Apache
    print_info "Restarting Apache..."
    if ! $sudo_cmd systemctl restart apache2 2>/dev/null; then
        print_error "Failed to restart Apache"
        return 1
    fi
    print_ok "Apache restarted"

    # Start MySQL if not running
    print_info "Starting MySQL service..."
    $sudo_cmd systemctl start mysql 2>/dev/null || true
    $sudo_cmd systemctl enable mysql 2>/dev/null || true

    print_ok "LAMP stack installation complete"
    print_subsection "Service Status"
    echo "  Apache2: $(systemctl is-active apache2 || echo 'inactive')"
    echo "  MySQL:   $(systemctl is-active mysql || echo 'inactive')"
    echo "  PHP:     $(php -v 2>/dev/null | head -n 1 || echo 'not found')"
    echo ""

    return 0
}

# Get LAMP installation status
get_lamp_status() {
    local status="not-installed"

    if command_exists apache2; then
        status="installed"
    fi

    echo "$status"
}

# Verify LAMP installation
verify_lamp() {
    print_section "Verifying LAMP Installation"

    local all_ok=true

    # Check Apache
    if command_exists apache2ctl; then
        local apache_version
        apache_version=$(apache2ctl -v 2>/dev/null | grep "Apache" | head -n 1)
        print_ok "Apache2: $apache_version"
    else
        print_warning "Apache2 not found"
        all_ok=false
    fi

    # Check MySQL
    if command_exists mysql; then
        local mysql_version
        mysql_version=$(mysql --version 2>/dev/null)
        print_ok "MySQL: $mysql_version"
    else
        print_warning "MySQL not found"
        all_ok=false
    fi

    # Check PHP
    if command_exists php; then
        local php_version
        php_version=$(php -v 2>/dev/null | head -n 1)
        print_ok "PHP: $php_version"
    else
        print_warning "PHP not found"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_ok "LAMP stack is fully installed"
        return 0
    else
        print_warning "Some LAMP components are missing"
        return 1
    fi
}

# Export functions
export -f install_lamp
export -f get_lamp_status
export -f verify_lamp
