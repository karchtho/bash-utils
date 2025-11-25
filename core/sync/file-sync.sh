#!/bin/bash
# File Synchronization System
# Syncs files between host and VMs using SSH/SCP

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Sync file from host to VM
sync_to_vm() {
    local vm_ip=$1
    local local_path=$2
    local vm_path=$3
    local vm_user=${4:-ubuntu}

    print_section "Syncing to VM"

    # Validate inputs
    [[ -z "$vm_ip" ]] && { print_error "VM IP required"; return 1; }
    [[ -z "$local_path" ]] && { print_error "Local path required"; return 1; }
    [[ -z "$vm_path" ]] && { print_error "VM path required"; return 1; }

    # Check if local path exists
    if [[ ! -e "$local_path" ]]; then
        print_error "Local path does not exist: $local_path"
        return 1
    fi

    print_info "Syncing: $local_path -> $vm_user@$vm_ip:$vm_path"
    echo ""

    # Use rsync if available, fall back to scp
    if command_exists rsync; then
        print_info "Using rsync for synchronization..."
        if rsync -avz -e ssh "$local_path" "$vm_user@$vm_ip:$vm_path" 2>/dev/null; then
            print_ok "Sync completed successfully"
            return 0
        else
            print_error "Rsync sync failed"
            return 1
        fi
    else
        print_info "Using scp for synchronization..."
        if scp -r "$local_path" "$vm_user@$vm_ip:$vm_path" 2>/dev/null; then
            print_ok "Sync completed successfully"
            return 0
        else
            print_error "SCP sync failed"
            return 1
        fi
    fi
}

# Sync file from VM to host
sync_from_vm() {
    local vm_ip=$1
    local vm_path=$2
    local local_path=$3
    local vm_user=${4:-ubuntu}

    print_section "Syncing from VM"

    # Validate inputs
    [[ -z "$vm_ip" ]] && { print_error "VM IP required"; return 1; }
    [[ -z "$vm_path" ]] && { print_error "VM path required"; return 1; }
    [[ -z "$local_path" ]] && { print_error "Local path required"; return 1; }

    print_info "Syncing: $vm_user@$vm_ip:$vm_path -> $local_path"
    echo ""

    # Create local directory if it doesn't exist
    mkdir -p "$(dirname "$local_path")"

    # Use rsync if available, fall back to scp
    if command_exists rsync; then
        print_info "Using rsync for synchronization..."
        if rsync -avz -e ssh "$vm_user@$vm_ip:$vm_path" "$local_path" 2>/dev/null; then
            print_ok "Sync completed successfully"
            return 0
        else
            print_error "Rsync sync failed"
            return 1
        fi
    else
        print_info "Using scp for synchronization..."
        if scp -r "$vm_user@$vm_ip:$vm_path" "$local_path" 2>/dev/null; then
            print_ok "Sync completed successfully"
            return 0
        else
            print_error "SCP sync failed"
            return 1
        fi
    fi
}

# Bidirectional sync (watch for changes)
sync_watch() {
    local vm_ip=$1
    local local_path=$2
    local vm_path=$3
    local vm_user=${4:-ubuntu}

    print_section "Watching for file changes"

    if ! command_exists inotifywait; then
        print_error "inotifywait not found. Install inotify-tools: sudo apt-get install inotify-tools"
        return 1
    fi

    print_info "Watching: $local_path"
    print_info "Syncing to: $vm_user@$vm_ip:$vm_path"
    echo "Press Ctrl+C to stop watching"
    echo ""

    # Watch for file changes and sync
    inotifywait -m -r -e modify,create,delete "$local_path" |
    while read -r path action file; do
        print_info "Change detected: $action - $file"
        sync_to_vm "$vm_ip" "$local_path" "$vm_path" "$vm_user"
    done

    return 0
}

# Setup SSH key-based authentication
setup_ssh_auth() {
    local vm_ip=$1
    local public_key_path=${2:-${HOME}/.ssh/id_ed25519.pub}
    local vm_user=${3:-ubuntu}

    print_section "Setting up SSH key authentication"

    # Check if public key exists
    if [[ ! -f "$public_key_path" ]]; then
        print_error "Public key not found: $public_key_path"
        return 1
    fi

    print_info "Adding SSH public key to VM..."
    print_info "Target: $vm_user@$vm_ip"
    echo ""

    # Read the public key
    local public_key
    public_key=$(<"$public_key_path")

    # Add key to VM's authorized_keys via SSH with password auth
    if ssh "$vm_user@$vm_ip" "mkdir -p ~/.ssh && echo '$public_key' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" 2>/dev/null; then
        print_ok "SSH key installed successfully"
        echo ""
        print_info "You can now connect without password:"
        echo "  ssh $vm_user@$vm_ip"
        return 0
    else
        print_error "Failed to install SSH key"
        return 1
    fi
}

# Test connectivity to VM
test_vm_connection() {
    local vm_ip=$1
    local vm_user=${2:-ubuntu}

    print_section "Testing VM Connectivity"

    if ! ping -c 1 -W 2 "$vm_ip" > /dev/null 2>&1; then
        print_warning "VM is not reachable: $vm_ip"
        return 1
    fi

    print_ok "VM is reachable: $vm_ip"

    # Test SSH connectivity
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$vm_user@$vm_ip" "echo OK" > /dev/null 2>&1; then
        print_ok "SSH connectivity successful"
        return 0
    else
        print_warning "SSH connectivity failed - may require password setup"
        return 0
    fi
}

# Export functions
export -f sync_to_vm
export -f sync_from_vm
export -f sync_watch
export -f setup_ssh_auth
export -f test_vm_connection
