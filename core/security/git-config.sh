#!/bin/bash
# Git Configuration Manager
# Configures Git with user info and SSH key integration

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Configure Git user identity
configure_git_user() {
    local git_name=${1:-}
    local git_email=${2:-}

    print_section "Configuring Git User Identity"

    # Prompt for user info if not provided
    if [[ -z "$git_name" ]]; then
        echo "Enter Git user name (e.g., John Doe):"
        read -r git_name
        [[ -z "$git_name" ]] && {
            print_error "Git user name is required"
            return 1
        }
    fi

    if [[ -z "$git_email" ]]; then
        echo "Enter Git email (e.g., john@example.com):"
        read -r git_email
        [[ -z "$git_email" ]] && {
            print_error "Git email is required"
            return 1
        }
    fi

    # Validate email format
    if ! [[ "$git_email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid email format: $git_email"
        return 1
    fi

    print_info "Setting Git user.name to: $git_name"
    git config --global user.name "$git_name"

    print_info "Setting Git user.email to: $git_email"
    git config --global user.email "$git_email"

    print_ok "Git user configured"
    echo ""

    return 0
}

# Configure Git SSH defaults
configure_git_ssh() {
    local key_name=${1:-id_ed25519}

    print_section "Configuring Git SSH"

    # Set SSH as the protocol for GitHub URLs
    print_info "Setting SSH as Git protocol..."
    git config --global url."git@github.com:".insteadOf "https://github.com/"

    # Enable SSH agent support
    git config --global core.sshCommand "ssh -i ~/.ssh/${key_name}"

    print_ok "Git SSH configured"
    echo ""

    return 0
}

# Configure Git useful defaults
configure_git_defaults() {
    print_section "Configuring Git Defaults"

    # Use main as default branch
    print_info "Setting default branch to main..."
    git config --global init.defaultBranch main

    # Better diff output
    print_info "Configuring diff options..."
    git config --global diff.colorMoved dimmed_zebra
    git config --global diff.coloring auto

    # Auto-push to matching branches
    git config --global push.default simple

    # Rebase by default for pull
    git config --global pull.rebase false

    # Configure colors
    git config --global color.ui auto
    git config --global color.status auto
    git config --global color.diff auto
    git config --global color.branch auto

    # Useful aliases
    print_info "Setting up git aliases..."
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.visual "log --graph --oneline --all"
    git config --global alias.amend "commit --amend --no-edit"

    # Performance optimization
    git config --global feature.manyFiles true

    print_ok "Git defaults configured"
    echo ""

    return 0
}

# Setup Git GPG signing (optional)
configure_git_gpg() {
    print_section "Configuring Git GPG Signing (Optional)"

    if ! command_exists gpg; then
        print_warning "GPG not found, skipping GPG configuration"
        return 0
    fi

    echo "Do you want to enable GPG signing for commits? (y/n)"
    read -r response
    [[ ! "$response" =~ [Yy] ]] && return 0

    # Find default GPG key
    local gpg_key
    gpg_key=$(gpg --list-secret-keys --keyid-format SHORT 2>/dev/null | grep "uid" | head -n 1 | awk '{print $NF}')

    if [[ -z "$gpg_key" ]]; then
        print_warning "No GPG keys found"
        return 0
    fi

    print_info "Setting GPG key for signing..."
    git config --global user.signingKey "$gpg_key"
    git config --global commit.gpgSign true

    print_ok "GPG signing configured with key: $gpg_key"
    echo ""

    return 0
}

# Display Git configuration
display_git_config() {
    print_section "Current Git Configuration"
    echo ""

    print_subsection "User Information"
    echo "  Name:  $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"
    echo ""

    print_subsection "SSH Configuration"
    echo "  SSH Command: $(git config --global core.sshCommand || echo 'default')"
    echo "  Protocol: $(git config --global url.\"git@github.com:\".insteadOf || echo 'https')"
    echo ""

    print_subsection "Aliases"
    git config --global --get-regexp alias | sed 's/^/  /' || echo "  (no aliases)"
    echo ""

    return 0
}

# Verify Git configuration
verify_git_config() {
    print_section "Verifying Git Configuration"

    local all_ok=true

    # Check Git is installed
    if command_exists git; then
        print_ok "Git is installed"
    else
        print_warning "Git is not installed"
        all_ok=false
    fi

    # Check user config
    local git_name
    git_name=$(git config --global user.name)
    if [[ -n "$git_name" ]]; then
        print_ok "Git user configured: $git_name"
    else
        print_warning "Git user name not configured"
        all_ok=false
    fi

    # Check email config
    local git_email
    git_email=$(git config --global user.email)
    if [[ -n "$git_email" ]]; then
        print_ok "Git email configured: $git_email"
    else
        print_warning "Git email not configured"
        all_ok=false
    fi

    echo ""

    if $all_ok; then
        print_ok "Git configuration is complete"
        return 0
    else
        print_warning "Git configuration incomplete"
        return 1
    fi
}

# Export functions
export -f configure_git_user
export -f configure_git_ssh
export -f configure_git_defaults
export -f configure_git_gpg
export -f display_git_config
export -f verify_git_config
