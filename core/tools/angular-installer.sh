#!/bin/bash
# Angular Standalone Project Installer
# Installs Angular CLI and creates standalone projects

# Source required libraries
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$PROJECT_ROOT/core/lib/colors.sh"
source "$PROJECT_ROOT/core/lib/error-handler.sh"
source "$PROJECT_ROOT/core/lib/validation.sh"
source "$PROJECT_ROOT/core/lib/common.sh"

# Angular version (latest LTS)
ANGULAR_VERSION="${ANGULAR_VERSION:-latest}"

# Install Angular CLI globally
install_angular_cli() {
    local version=${1:-$ANGULAR_VERSION}

    print_section "Installing Angular CLI"

    # Check if Node.js is installed
    if ! command_exists node; then
        print_error "Node.js is required. Please install Node.js first."
        return 1
    fi

    local node_version
    node_version=$(node --version)
    print_info "Using Node.js: $node_version"

    # Check if npm is installed
    if ! command_exists npm; then
        print_error "npm is required. Please install Node.js first."
        return 1
    fi

    # Check if Angular CLI is already installed
    if command_exists ng; then
        local current_version
        current_version=$(ng version 2>/dev/null | grep -i "angular cli" | head -n 1 || echo "unknown")
        print_info "Angular CLI already installed: $current_version"
        return 0
    fi

    # Install Angular CLI
    print_info "Installing Angular CLI v$version..."
    if ! npm install -g @angular/cli@$version 2>/dev/null; then
        print_error "Failed to install Angular CLI"
        return 1
    fi

    # Verify installation
    if ! command_exists ng; then
        print_error "Angular CLI installation failed"
        return 1
    fi

    local ng_version
    ng_version=$(ng version 2>/dev/null | head -n 1)
    print_ok "Angular CLI installed: $ng_version"

    # Install additional development tools
    print_info "Installing additional development tools..."
    npm install -g @angular-eslint/schematics 2>/dev/null || true

    print_ok "Angular CLI installation complete"
    echo ""

    return 0
}

# Create a new Angular standalone project
create_angular_project() {
    local project_name=$1
    local project_path=${2:-.}

    if [[ -z "$project_name" ]]; then
        print_error "Project name required"
        return 1
    fi

    # Validate project name (no spaces or special chars)
    if ! [[ "$project_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Invalid project name. Use only letters, numbers, hyphens, and underscores."
        return 1
    fi

    # Check if ng command is available
    if ! command_exists ng; then
        print_error "Angular CLI not found. Please install it first."
        return 1
    fi

    print_section "Creating Angular Standalone Project"
    print_info "Project name: $project_name"
    print_info "Location: $project_path"

    # Create directory if it doesn't exist
    mkdir -p "$project_path"
    cd "$project_path" || return 1

    # Create Angular project with standalone components
    print_info "Generating project structure..."
    if ! ng new "$project_name" --standalone --routing --skip-git 2>/dev/null; then
        print_error "Failed to create Angular project"
        return 1
    fi

    cd "$project_name" || return 1

    # Install dependencies
    print_info "Installing dependencies..."
    if ! npm install 2>/dev/null; then
        print_warning "Some dependencies failed to install"
    fi

    print_ok "Angular project created: $project_name"
    print_subsection "Next Steps"
    echo "  cd $project_name"
    echo "  npm start"
    echo ""

    return 0
}

# Generate a new Angular standalone component
generate_component() {
    local component_name=$1
    local component_path=${2:-.}

    if [[ -z "$component_name" ]]; then
        print_error "Component name required"
        return 1
    fi

    if ! command_exists ng; then
        print_error "Angular CLI not found"
        return 1
    fi

    print_info "Generating component: $component_name"
    ng generate component "$component_name" --standalone 2>/dev/null || {
        print_error "Failed to generate component"
        return 1
    }

    print_ok "Component generated: $component_name"
    return 0
}

# Generate a new Angular service
generate_service() {
    local service_name=$1

    if [[ -z "$service_name" ]]; then
        print_error "Service name required"
        return 1
    fi

    if ! command_exists ng; then
        print_error "Angular CLI not found"
        return 1
    fi

    print_info "Generating service: $service_name"
    ng generate service "$service_name" 2>/dev/null || {
        print_error "Failed to generate service"
        return 1
    }

    print_ok "Service generated: $service_name"
    return 0
}

# Get Angular installation status
get_angular_status() {
    if command_exists ng; then
        ng version 2>/dev/null | head -n 1 || echo "installed"
    else
        echo "not-installed"
    fi
}

# Verify Angular installation
verify_angular() {
    print_section "Verifying Angular Installation"

    local all_ok=true

    # Check Angular CLI
    if command_exists ng; then
        local ng_version
        ng_version=$(ng version 2>/dev/null | head -n 1)
        print_ok "Angular CLI: $ng_version"
    else
        print_warning "Angular CLI not found"
        all_ok=false
    fi

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

    echo ""

    if $all_ok; then
        print_ok "Angular environment is ready"
        return 0
    else
        print_warning "Some Angular dependencies are missing"
        return 1
    fi
}

# Export functions
export -f install_angular_cli
export -f create_angular_project
export -f generate_component
export -f generate_service
export -f get_angular_status
export -f verify_angular
