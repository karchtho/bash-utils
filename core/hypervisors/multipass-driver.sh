#!/bin/bash
# Multipass Hypervisor Driver
# Implements the hypervisor interface for Multipass

# Source the interface
source "$(dirname "${BASH_SOURCE[0]}")/hypervisor-interface.sh"

# Check if Multipass is available
driver_is_available() {
    command_exists multipass
}

# Get Multipass version
driver_get_version() {
    if command_exists multipass; then
        multipass version | head -n 1 | awk '{print $NF}' || echo "unknown"
    else
        return 1
    fi
}

# Create a new VM with Multipass
driver_create_vm() {
    local vm_name=$1
    local cpus=$2
    local memory=$3
    local disk=$4
    local image=$5

    validate_vm_name "$vm_name" || return 1

    print_info "Creating Multipass VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would create VM: multipass launch -n $vm_name --cpus $cpus --memory $memory --disk $disk $image"
        return 0
    fi

    if multipass launch -n "$vm_name" --cpus "$cpus" --memory "$memory" --disk "$disk" "$image"; then
        print_ok "VM created: $vm_name"
        return 0
    else
        print_error "Failed to create VM: $vm_name"
        return 1
    fi
}

# Start a stopped Multipass VM
driver_start_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_info "Starting VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would start: multipass start $vm_name"
        return 0
    fi

    if multipass start "$vm_name"; then
        print_ok "VM started: $vm_name"
        return 0
    else
        print_error "Failed to start VM: $vm_name"
        return 1
    fi
}

# Stop a running Multipass VM
driver_stop_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_info "Stopping VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would stop: multipass stop $vm_name"
        return 0
    fi

    if multipass stop "$vm_name"; then
        print_ok "VM stopped: $vm_name"
        return 0
    else
        print_error "Failed to stop VM: $vm_name"
        return 1
    fi
}

# Delete a Multipass VM
driver_delete_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_warning "Deleting VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would delete: multipass delete --purge $vm_name"
        return 0
    fi

    if multipass delete --purge "$vm_name"; then
        print_ok "VM deleted: $vm_name"
        return 0
    else
        print_error "Failed to delete VM: $vm_name"
        return 1
    fi
}

# Execute a command in a Multipass VM
driver_exec_command() {
    local vm_name=$1
    shift
    local -a command=("$@")

    validate_vm_name "$vm_name" || return 1

    print_debug "Executing in $vm_name: ${command[*]}"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would execute: multipass exec $vm_name -- ${command[*]}"
        return 0
    fi

    multipass exec "$vm_name" -- "${command[@]}"
}

# List all Multipass VMs
driver_list_vms() {
    if command_exists multipass; then
        multipass list --format json | jq -r '.list[] | .name' 2>/dev/null || multipass list | tail -n +2 | awk '{print $1}'
    else
        return 1
    fi
}

# Get status of a Multipass VM
driver_get_vm_status() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    local status
    status=$(multipass list --format json | jq -r ".list[] | select(.name==\"$vm_name\") | .status" 2>/dev/null)

    if [[ -z "$status" ]]; then
        echo "not-found"
    else
        case "$status" in
            Running) echo "running" ;;
            Stopped) echo "stopped" ;;
            Suspended) echo "stopped" ;;
            *) echo "error" ;;
        esac
    fi
}

# Get IP address of a Multipass VM
driver_get_vm_ip() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    multipass list --format json | jq -r ".list[] | select(.name==\"$vm_name\") | .ipv4[0]" 2>/dev/null || {
        # Fallback to text parsing if jq fails
        multipass list | grep "$vm_name" | awk '{print $3}'
    }
}

# Mount a local directory in a Multipass VM
driver_mount_directory() {
    local vm_name=$1
    local local_path=$2
    local vm_path=$3

    validate_vm_name "$vm_name" || return 1

    print_info "Mounting $local_path to $vm_name:$vm_path"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would mount: multipass mount $local_path $vm_name:$vm_path"
        return 0
    fi

    if multipass mount "$local_path" "$vm_name:$vm_path"; then
        print_ok "Directory mounted"
        return 0
    else
        print_error "Failed to mount directory"
        return 1
    fi
}

# Get information about a Multipass VM
driver_get_vm_info() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    multipass info "$vm_name" --format json 2>/dev/null || multipass info "$vm_name"
}

# Export functions for use in other scripts
export -f driver_is_available
export -f driver_get_version
export -f driver_create_vm
export -f driver_start_vm
export -f driver_stop_vm
export -f driver_delete_vm
export -f driver_exec_command
export -f driver_list_vms
export -f driver_get_vm_status
export -f driver_get_vm_ip
export -f driver_mount_directory
export -f driver_get_vm_info
