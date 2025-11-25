#!/bin/bash
# SSH Key Management
# Generates and manages ed25519 SSH keys for secure authentication

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Generate SSH key pair
generate_ssh_key() {
    local key_name=${1:-id_ed25519}
    local key_path="${HOME}/.ssh/${key_name}"
    local key_comment=${2:-"$(whoami)@$(hostname)-$(date +%s)"}

    print_section "Generating SSH Key Pair"

    # Create .ssh directory if it doesn't exist
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    # Check if key already exists
    if [[ -f "$key_path" ]]; then
        print_info "SSH key already exists: $key_path"
        return 0
    fi

    # Generate ed25519 key (modern, secure, smaller than RSA)
    print_info "Generating ed25519 SSH key pair..."
    print_info "Key name: $key_name"
    print_info "Key path: $key_path"
    echo ""

    if ! ssh-keygen -t ed25519 -f "$key_path" -N "" -C "$key_comment" 2>/dev/null; then
        print_error "Failed to generate SSH key"
        return 1
    fi

    # Set proper permissions
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"

    local key_fingerprint
    key_fingerprint=$(ssh-keygen -lf "$key_path" 2>/dev/null | awk '{print $2}')

    print_ok "SSH key pair generated successfully"
    echo "  Key path: $key_path"
    echo "  Public key: ${key_path}.pub"
    echo "  Fingerprint: $key_fingerprint"
    echo ""

    return 0
}

# Add SSH key to ssh-agent
add_key_to_agent() {
    local key_name=${1:-id_ed25519}
    local key_path="${HOME}/.ssh/${key_name}"

    print_section "Adding SSH Key to ssh-agent"

    # Check if key exists
    if [[ ! -f "$key_path" ]]; then
        print_error "SSH key not found: $key_path"
        return 1
    fi

    # Start ssh-agent if not running
    if ! pgrep -u "$USER" ssh-agent > /dev/null; then
        print_info "Starting ssh-agent..."
        eval "$(ssh-agent -s)" > /dev/null
    fi

    # Add key to agent
    print_info "Adding key to ssh-agent..."
    if ! ssh-add "$key_path" 2>/dev/null; then
        print_error "Failed to add key to ssh-agent"
        return 1
    fi

    print_ok "SSH key added to ssh-agent"
    echo ""

    return 0
}

# Display SSH public key for copying
display_ssh_public_key() {
    local key_name=${1:-id_ed25519}
    local key_path="${HOME}/.ssh/${key_name}.pub"

    print_section "SSH Public Key"

    if [[ ! -f "$key_path" ]]; then
        print_error "SSH public key not found: $key_path"
        return 1
    fi

    echo ""
    echo "Copy the following key and add it to your Git hosting service (GitHub, GitLab, etc):"
    echo ""
    cat "$key_path"
    echo ""
    echo ""

    return 0
}

# Setup SSH config for GitHub
setup_ssh_config() {
    local config_file="${HOME}/.ssh/config"
    local key_name=${1:-id_ed25519}

    print_section "Setting up SSH config"

    # Create .ssh directory if needed
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    # Check if GitHub entry already exists
    if grep -q "Host github.com" "$config_file" 2>/dev/null; then
        print_info "GitHub SSH config already exists"
        return 0
    fi

    # Create SSH config if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        touch "$config_file"
        chmod 600 "$config_file"
    fi

    # Add GitHub configuration
    cat >> "$config_file" << EOF

# GitHub SSH Configuration
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/${key_name}
    AddKeysToAgent yes
    IdentitiesOnly yes

EOF

    print_ok "SSH config updated for GitHub"
    echo "  Config file: $config_file"
    echo ""

    return 0
}

# Test SSH connection
test_ssh_connection() {
    local host=${1:-github.com}

    print_section "Testing SSH Connection"
    echo "  Host: $host"
    echo ""

    # Suppress strict host key checking for first connection
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -T "$host" 2>&1 | grep -q "You've successfully authenticated"; then
        print_ok "SSH connection successful to $host"
        return 0
    else
        print_warning "SSH connection to $host may need key setup"
        return 0
    fi
}

# Get SSH key status
get_ssh_status() {
    local key_path="${HOME}/.ssh/id_ed25519"

    if [[ -f "$key_path" ]]; then
        echo "ed25519 key exists"
    else
        echo "no-ssh-key"
    fi
}

# Verify SSH setup
verify_ssh() {
    print_section "Verifying SSH Setup"

    local all_ok=true

    # Check SSH directory
    if [[ -d "${HOME}/.ssh" ]]; then
        print_ok "SSH directory exists"
    else
        print_warning "SSH directory not found"
        all_ok=false
    fi

    # Check ed25519 key
    if [[ -f "${HOME}/.ssh/id_ed25519" ]]; then
        local fingerprint
        fingerprint=$(ssh-keygen -lf "${HOME}/.ssh/id_ed25519" 2>/dev/null | awk '{print $2}')
        print_ok "SSH key exists: $fingerprint"
    else
        print_warning "SSH ed25519 key not found"
        all_ok=false
    fi

    # Check SSH config
    if [[ -f "${HOME}/.ssh/config" ]]; then
        print_ok "SSH config exists"
    else
        print_info "SSH config not configured"
    fi

    echo ""

    if $all_ok; then
        print_ok "SSH setup is complete"
        return 0
    else
        print_warning "SSH setup incomplete"
        return 1
    fi
}

# Export functions
export -f generate_ssh_key
export -f add_key_to_agent
export -f display_ssh_public_key
export -f setup_ssh_config
export -f test_ssh_connection
export -f get_ssh_status
export -f verify_ssh
