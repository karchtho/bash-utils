#!/bin/bash
# Git and SSH Setup Integration
# Complete setup for SSH keys, Git configuration, and remote synchronization

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Source security components
source "$SCRIPT_DIR/core/security/ssh-keys.sh"
source "$SCRIPT_DIR/core/security/git-config.sh"
source "$SCRIPT_DIR/core/sync/file-sync.sh"

# Complete setup flow
setup_git_ssh_complete() {
    print_section "Setting up Git and SSH"
    echo ""

    # Step 1: Generate SSH keys
    print_subsection "Step 1: SSH Key Generation"
    if generate_ssh_key "id_ed25519"; then
        print_ok "SSH key generated"
    else
        print_warning "SSH key generation failed or already exists"
    fi
    echo ""

    # Step 2: Configure Git user
    print_subsection "Step 2: Git User Configuration"
    if configure_git_user; then
        print_ok "Git user configured"
    else
        print_warning "Git user configuration skipped"
    fi
    echo ""

    # Step 3: Configure Git SSH
    print_subsection "Step 3: Git SSH Configuration"
    if configure_git_ssh "id_ed25519"; then
        print_ok "Git SSH configured"
    else
        print_warning "Git SSH configuration failed"
    fi
    echo ""

    # Step 4: Configure Git defaults
    print_subsection "Step 4: Git Defaults"
    if configure_git_defaults; then
        print_ok "Git defaults configured"
    else
        print_warning "Git defaults configuration failed"
    fi
    echo ""

    # Step 5: Setup SSH config
    print_subsection "Step 5: SSH Configuration"
    if setup_ssh_config "id_ed25519"; then
        print_ok "SSH config updated"
    else
        print_warning "SSH config setup failed"
    fi
    echo ""

    # Step 6: Display public key
    print_subsection "Step 6: SSH Public Key"
    display_ssh_public_key "id_ed25519"

    print_section "Git and SSH Setup Complete"
    echo ""
    print_info "Next steps:"
    echo "  1. Copy your SSH public key to GitHub/GitLab/Gitea"
    echo "  2. Test SSH connection: ssh -T git@github.com"
    echo "  3. Clone repositories using SSH"
    echo ""

    return 0
}

# Quick setup with defaults
setup_git_ssh_quick() {
    local git_name=${1:-}
    local git_email=${2:-}

    print_section "Quick Git and SSH Setup"
    echo ""

    # Generate SSH key
    if [[ ! -f "${HOME}/.ssh/id_ed25519" ]]; then
        generate_ssh_key "id_ed25519" || return 1
    else
        print_info "SSH key already exists"
    fi
    echo ""

    # Configure Git
    if [[ -z "$git_name" ]] || [[ -z "$git_email" ]]; then
        print_error "Git name and email are required for quick setup"
        print_info "Usage: setup_git_ssh_quick <name> <email>"
        return 1
    fi

    configure_git_user "$git_name" "$git_email" || return 1
    configure_git_ssh "id_ed25519" || return 1
    configure_git_defaults || return 1
    setup_ssh_config "id_ed25519" || return 1

    print_ok "Quick setup complete"
    echo ""

    return 0
}

# Setup VM synchronization
setup_vm_sync() {
    local vm_ip=$1
    local vm_user=${2:-ubuntu}

    if [[ -z "$vm_ip" ]]; then
        print_error "VM IP address required"
        return 1
    fi

    print_section "Setting up VM Synchronization"
    echo ""

    # Test connection
    if ! test_vm_connection "$vm_ip" "$vm_user"; then
        print_warning "VM connection test failed"
    fi
    echo ""

    # Setup SSH key
    print_subsection "Setting up SSH key authentication"
    if setup_ssh_auth "$vm_ip" "${HOME}/.ssh/id_ed25519.pub" "$vm_user"; then
        print_ok "SSH key setup complete"
    else
        print_warning "SSH key setup failed"
    fi
    echo ""

    print_ok "VM synchronization setup complete"
    return 0
}

# Export functions
export -f setup_git_ssh_complete
export -f setup_git_ssh_quick
export -f setup_vm_sync
