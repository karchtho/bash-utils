#!/bin/bash
# LAMP Stack Installer with PHP-FPM
# Installs Linux (Ubuntu), Apache2, MariaDB/MySQL, PHP with FPM configuration
# Includes phpMyAdmin, database user setup, and environment-specific configuration
# Used both locally and in VMs

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Configuration defaults - HARDCODED DATABASE USER
LAMP_ENVIRONMENT="${LAMP_ENVIRONMENT:-development}"
LAMP_DB_USER="superadmin"
LAMP_DB_PASSWORD="superpass"
LAMP_PHPMYADMIN_PASS="${LAMP_PHPMYADMIN_PASS:-phpmyadmin}"

# Install LAMP stack with PHP-FPM
install_lamp() {
    local environment="${1:-$LAMP_ENVIRONMENT}"

    print_section "Installing LAMP Stack"
    print_info "Environment: $environment"
    echo ""

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

    # Enable Apache modules for FPM
    print_info "Enabling Apache modules (rewrite, ssl, proxy, proxy_fcgi)..."
    $sudo_cmd a2enmod rewrite 2>/dev/null || true
    $sudo_cmd a2enmod ssl 2>/dev/null || true
    $sudo_cmd a2enmod proxy 2>/dev/null || true
    $sudo_cmd a2enmod proxy_fcgi 2>/dev/null || true
    $sudo_cmd a2enmod setenvif 2>/dev/null || true
    print_ok "Apache modules enabled"

    # Install MariaDB Server
    print_info "Installing MariaDB Server..."
    if ! $sudo_cmd apt-get install -y mariadb-server 2>/dev/null; then
        print_error "Failed to install MariaDB Server"
        return 1
    fi
    print_ok "MariaDB Server installed"

    # Install PHP-FPM and extensions
    print_info "Installing PHP-FPM and extensions..."
    local php_packages="php php-fpm php-mysql php-cli php-curl php-json php-mbstring php-xml php-zip php-intl php-gd"

    if ! $sudo_cmd apt-get install -y $php_packages 2>/dev/null; then
        print_error "Failed to install PHP-FPM"
        return 1
    fi
    print_ok "PHP-FPM installed"

    # Configure environment-specific settings
    configure_lamp_environment "$sudo_cmd" "$environment"

    # Configure phpMyAdmin
    install_phpmyadmin "$sudo_cmd"

    # Setup database user and tables
    setup_database_user "$sudo_cmd"

    # Restart services
    print_info "Restarting services..."
    $sudo_cmd systemctl restart apache2 2>/dev/null || true
    $sudo_cmd systemctl restart php*-fpm 2>/dev/null || true
    $sudo_cmd systemctl restart mysql 2>/dev/null || true

    print_ok "LAMP stack installation complete"
    print_subsection "Service Status"
    echo "  Apache2:  $(systemctl is-active apache2 || echo 'inactive')"
    echo "  MySQL:    $(systemctl is-active mysql || echo 'inactive')"
    echo "  PHP-FPM:  $(systemctl is-active php*-fpm 2>/dev/null | head -1 || echo 'inactive')"
    echo "  PHP:      $(php -v 2>/dev/null | head -n 1 || echo 'not found')"
    echo ""
    print_subsection "Database Access"
    echo "  User:     $LAMP_DB_USER"
    echo "  Password: $LAMP_DB_PASSWORD"
    echo ""
    print_subsection "phpMyAdmin"
    echo "  URL:      http://localhost/phpmyadmin"
    echo "  User:     $LAMP_DB_USER"
    echo "  Password: $LAMP_DB_PASSWORD"
    echo ""

    return 0
}

# Configure environment-specific settings
configure_lamp_environment() {
    local sudo_cmd="$1"
    local environment="$2"

    print_info "Configuring for $environment environment..."

    case "$environment" in
        development)
            configure_php_development "$sudo_cmd"
            configure_apache_development "$sudo_cmd"
            configure_mysql_development "$sudo_cmd"
            ;;
        test)
            configure_php_test "$sudo_cmd"
            configure_apache_test "$sudo_cmd"
            configure_mysql_test "$sudo_cmd"
            ;;
        production)
            configure_php_production "$sudo_cmd"
            configure_apache_production "$sudo_cmd"
            configure_mysql_production "$sudo_cmd"
            ;;
        *)
            print_warning "Unknown environment: $environment, using defaults"
            ;;
    esac
}

# Development PHP configuration
configure_php_development() {
    local sudo_cmd="$1"
    print_info "Configuring PHP for development..."

    $sudo_cmd tee /etc/php/*/mods-available/development-settings.ini > /dev/null << 'EOF'
; Development environment settings
error_reporting = E_ALL
display_errors = On
display_startup_errors = On
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M
opcache.enable = 0
opcache.enable_cli = 0
EOF

    $sudo_cmd phpenmod development-settings 2>/dev/null || true
    print_ok "PHP development configuration applied"
}

# Test PHP configuration
configure_php_test() {
    local sudo_cmd="$1"
    print_info "Configuring PHP for testing..."

    $sudo_cmd tee /etc/php/*/mods-available/test-settings.ini > /dev/null << 'EOF'
; Testing environment settings
error_reporting = E_ALL
display_errors = Off
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 256M
max_execution_time = 60
post_max_size = 32M
upload_max_filesize = 32M
opcache.enable = 1
opcache.enable_cli = 1
EOF

    $sudo_cmd phpenmod test-settings 2>/dev/null || true
    print_ok "PHP test configuration applied"
}

# Production PHP configuration
configure_php_production() {
    local sudo_cmd="$1"
    print_info "Configuring PHP for production..."

    $sudo_cmd tee /etc/php/*/mods-available/production-settings.ini > /dev/null << 'EOF'
; Production environment settings
error_reporting = E_CRITICAL | E_ERROR
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php_errors.log
memory_limit = 128M
max_execution_time = 30
post_max_size = 16M
upload_max_filesize = 16M
opcache.enable = 1
opcache.enable_cli = 0
opcache.revalidate_freq = 3600
EOF

    $sudo_cmd phpenmod production-settings 2>/dev/null || true
    print_ok "PHP production configuration applied"
}

# Development Apache configuration (with FPM)
configure_apache_development() {
    local sudo_cmd="$1"
    print_info "Configuring Apache for development (FPM mode)..."

    $sudo_cmd tee /etc/apache2/conf-available/development.conf > /dev/null << 'EOF'
# Development environment settings
ServerTokens Full
ServerSignature On
LogLevel info
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF

    $sudo_cmd a2enconf development 2>/dev/null || true
    print_ok "Apache development configuration applied"
}

# Test Apache configuration (with FPM)
configure_apache_test() {
    local sudo_cmd="$1"
    print_info "Configuring Apache for testing (FPM mode)..."

    $sudo_cmd tee /etc/apache2/conf-available/testing.conf > /dev/null << 'EOF'
# Test environment settings
ServerTokens Prod
ServerSignature Off
LogLevel warn
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF

    $sudo_cmd a2enconf testing 2>/dev/null || true
    print_ok "Apache test configuration applied"
}

# Production Apache configuration (with FPM and security headers)
configure_apache_production() {
    local sudo_cmd="$1"
    print_info "Configuring Apache for production (FPM mode)..."

    $sudo_cmd tee /etc/apache2/conf-available/production.conf > /dev/null << 'EOF'
# Production environment settings
ServerTokens Prod
ServerSignature Off
LogLevel crit
TraceEnable Off
Header always append X-Frame-Options SAMEORIGIN
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
<FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php-fpm.sock|fcgi://localhost"
</FilesMatch>
EOF

    $sudo_cmd a2enconf production 2>/dev/null || true
    print_ok "Apache production configuration applied"
}

# Development MySQL configuration
configure_mysql_development() {
    local sudo_cmd="$1"
    print_info "Configuring MySQL for development..."

    $sudo_cmd tee -a /etc/mysql/mariadb.conf.d/50-server.cnf > /dev/null << 'EOF'

# Development environment settings
general_log = 1
general_log_file = /var/log/mysql/query.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1
log_queries_not_using_indexes = 1
EOF

    print_ok "MySQL development configuration applied"
}

# Test MySQL configuration
configure_mysql_test() {
    local sudo_cmd="$1"
    print_info "Configuring MySQL for testing..."

    $sudo_cmd tee -a /etc/mysql/mariadb.conf.d/50-server.cnf > /dev/null << 'EOF'

# Test environment settings
general_log = 0
slow_query_log = 0
skip-name-resolve = 1
EOF

    print_ok "MySQL test configuration applied"
}

# Production MySQL configuration
configure_mysql_production() {
    local sudo_cmd="$1"
    print_info "Configuring MySQL for production..."

    $sudo_cmd tee -a /etc/mysql/mariadb.conf.d/50-server.cnf > /dev/null << 'EOF'

# Production environment settings
general_log = 0
slow_query_log = 0
skip-name-resolve = 1
max_connections = 100
max_allowed_packet = 64M
innodb_buffer_pool_size = 1G
query_cache_type = 1
query_cache_size = 16M
EOF

    print_ok "MySQL production configuration applied"
}

# Install phpMyAdmin non-interactively
install_phpmyadmin() {
    local sudo_cmd="$1"

    print_info "Installing phpMyAdmin non-interactively..."

    # Set password non-interactively using hardcoded credentials
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password $LAMP_DB_PASSWORD" | $sudo_cmd debconf-set-selections 2>/dev/null || true
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $LAMP_DB_PASSWORD" | $sudo_cmd debconf-set-selections 2>/dev/null || true
    echo "phpmyadmin phpmyadmin/app-password-confirm password $LAMP_DB_PASSWORD" | $sudo_cmd debconf-set-selections 2>/dev/null || true
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | $sudo_cmd debconf-set-selections 2>/dev/null || true

    if $sudo_cmd apt-get install -y phpmyadmin 2>/dev/null; then
        print_ok "phpMyAdmin installed (non-interactive mode with superpass credentials)"
    else
        print_warning "phpMyAdmin installation skipped or failed"
    fi
}

# Setup database user and default tables with HARDCODED credentials
setup_database_user() {
    local sudo_cmd="$1"

    print_info "Setting up database user with hardcoded credentials (superadmin/superpass)..."

    # Start MySQL if not running
    $sudo_cmd systemctl start mysql 2>/dev/null || true

    # Wait for MySQL to be ready (max 10 seconds)
    local max_attempts=10
    local attempt=0
    while ! $sudo_cmd mysqladmin ping -u root 2>/dev/null; do
        if [ $attempt -ge $max_attempts ]; then
            print_warning "MySQL took too long to start, skipping user setup"
            return 0
        fi
        sleep 1
        ((attempt++))
    done

    # Create admin user with HARDCODED password (superadmin / superpass)
    $sudo_cmd mysql -e "CREATE USER IF NOT EXISTS '$LAMP_DB_USER'@'localhost' IDENTIFIED BY '$LAMP_DB_PASSWORD';" 2>/dev/null || true
    $sudo_cmd mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$LAMP_DB_USER'@'localhost' WITH GRANT OPTION;" 2>/dev/null || true
    $sudo_cmd mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

    print_ok "Database user 'superadmin' configured with password 'superpass' and full privileges"
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

    # Check MariaDB/MySQL
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

    # Check PHP-FPM
    if systemctl is-active --quiet php*-fpm 2>/dev/null; then
        print_ok "PHP-FPM: running"
    else
        print_warning "PHP-FPM not running"
        all_ok=false
    fi

    # Check phpMyAdmin
    if [[ -d "/usr/share/phpmyadmin" ]]; then
        print_ok "phpMyAdmin: installed"
    else
        print_info "phpMyAdmin: not installed"
    fi

    echo ""

    if $all_ok; then
        print_ok "LAMP stack is fully installed and configured"
        return 0
    else
        print_warning "Some LAMP components need attention"
        return 1
    fi
}

# Export functions
export -f install_lamp
export -f get_lamp_status
export -f verify_lamp
export -f configure_lamp_environment
