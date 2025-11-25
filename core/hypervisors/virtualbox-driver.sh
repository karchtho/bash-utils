#!/bin/bash
# VirtualBox Hypervisor Driver
# Implements the hypervisor interface for VirtualBox

source "$(dirname "${BASH_SOURCE[0]}")/hypervisor-interface.sh"

# Check if VirtualBox is available
driver_is_available() {
    command_exists VBoxManage
}

# Get VirtualBox version
driver_get_version() {
    if command_exists VBoxManage; then
        VBoxManage --version | head -n 1
    else
        return 1
    fi
}

# Create a new VM with VirtualBox
driver_create_vm() {
    local vm_name=$1
    local cpus=$2
    local memory=$3
    local disk=$4
    local image=$5

    validate_vm_name "$vm_name" || return 1

    print_info "Creating VirtualBox VM: $vm_name"
    print_debug "  CPUs: $cpus, Memory: $memory, Disk: $disk, Image: $image"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would create VM: $vm_name"
        return 0
    fi

    # Create the VM
    if ! VBoxManage createvm --name "$vm_name" --ostype Ubuntu_64 --register 2>/dev/null; then
        print_error "Failed to create VM: $vm_name"
        return 1
    fi

    # Configure VM resources
    if ! VBoxManage modifyvm "$vm_name" --cpus "$cpus" --memory "$memory" 2>/dev/null; then
        print_error "Failed to configure VM resources"
        VBoxManage unregistervm "$vm_name" --delete 2>/dev/null || true
        return 1
    fi

    # Create storage controller
    if ! VBoxManage storagectl "$vm_name" --name "SATA" --add sata --controller IntelAhci 2>/dev/null; then
        print_error "Failed to create storage controller"
        VBoxManage unregistervm "$vm_name" --delete 2>/dev/null || true
        return 1
    fi

    print_ok "VM created: $vm_name"
    print_info "Note: VirtualBox requires manual disk image setup. See documentation for details."
    return 0
}

# Start a stopped VirtualBox VM
driver_start_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_info "Starting VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would start: VBoxManage startvm $vm_name --type headless"
        return 0
    fi

    if VBoxManage startvm "$vm_name" --type headless 2>/dev/null; then
        print_ok "VM started: $vm_name"
        sleep 2  # Wait for VM to start
        return 0
    else
        print_error "Failed to start VM: $vm_name"
        return 1
    fi
}

# Stop a running VirtualBox VM
driver_stop_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_info "Stopping VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would stop: VBoxManage controlvm $vm_name poweroff"
        return 0
    fi

    if VBoxManage controlvm "$vm_name" poweroff soft 2>/dev/null; then
        print_ok "VM stopped: $vm_name"
        return 0
    else
        # Try hard poweroff
        if VBoxManage controlvm "$vm_name" poweroff 2>/dev/null; then
            print_ok "VM stopped (hard): $vm_name"
            return 0
        else
            print_error "Failed to stop VM: $vm_name"
            return 1
        fi
    fi
}

# Delete a VirtualBox VM
driver_delete_vm() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    print_warning "Deleting VM: $vm_name"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would delete: VBoxManage unregistervm $vm_name --delete"
        return 0
    fi

    # Stop VM first if running
    local status
    status=$(driver_get_vm_status "$vm_name")
    if [[ "$status" == "running" ]]; then
        driver_stop_vm "$vm_name" || true
        sleep 1
    fi

    if VBoxManage unregistervm "$vm_name" --delete 2>/dev/null; then
        print_ok "VM deleted: $vm_name"
        return 0
    else
        print_error "Failed to delete VM: $vm_name"
        return 1
    fi
}

# Execute a command in a VirtualBox VM via SSH
driver_exec_command() {
    local vm_name=$1
    shift
    local -a command=("$@")

    validate_vm_name "$vm_name" || return 1

    # VirtualBox requires SSH to be configured - get IP first
    local vm_ip
    vm_ip=$(driver_get_vm_ip "$vm_name") || return 1

    if [[ -z "$vm_ip" || "$vm_ip" == "N/A" ]]; then
        print_error "Could not get IP for VM: $vm_name"
        return 1
    fi

    print_debug "Executing in $vm_name ($vm_ip): ${command[*]}"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would execute via SSH: ${command[*]}"
        return 0
    fi

    # Execute via SSH
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "ubuntu@$vm_ip" "${command[@]}"
}

# List all VirtualBox VMs
driver_list_vms() {
    if command_exists VBoxManage; then
        VBoxManage list vms | awk -F'"' '{print $2}'
    else
        return 1
    fi
}

# Get status of a VirtualBox VM
driver_get_vm_status() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    local status
    status=$(VBoxManage showvminfo "$vm_name" 2>/dev/null | grep "State:" | awk -F'State:' '{print $2}' | cut -d'(' -f1 | xargs)

    if [[ -z "$status" ]]; then
        echo "not-found"
        return 0
    fi

    case "$status" in
        running) echo "running" ;;
        stopped|poweroff) echo "stopped" ;;
        paused) echo "stopped" ;;
        *) echo "error" ;;
    esac
}

# Get IP address of a VirtualBox VM
driver_get_vm_ip() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    # VirtualBox doesn't provide direct IP access like Multipass
    # User must configure SSH access manually or via guest properties
    # For now, return placeholder that requires manual configuration
    local vm_ip
    vm_ip=$(VBoxManage guestproperty get "$vm_name" "/VirtualBox/GuestInfo/Net/0/V4/IP" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' || echo "")

    if [[ -z "$vm_ip" ]]; then
        # Try to get from DHCP server
        print_debug "IP not available yet in guest properties for $vm_name"
        echo "N/A"
        return 1
    fi

    echo "$vm_ip"
    return 0
}

# Mount a local directory in a VirtualBox VM (via shared folders)
driver_mount_directory() {
    local vm_name=$1
    local local_path=$2
    local vm_path=$3

    validate_vm_name "$vm_name" || return 1

    print_info "Setting up shared folder for $local_path at $vm_path"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "[DRY-RUN] Would create shared folder"
        return 0
    fi

    # Create shared folder
    if VBoxManage sharedfolder add "$vm_name" --name "${vm_path##*/}" --hostpath "$local_path" 2>/dev/null; then
        print_ok "Shared folder configured"
        print_info "Note: VM must mount this folder manually with: sudo mount -t vboxsf ${vm_path##*/} $vm_path"
        return 0
    else
        print_error "Failed to create shared folder"
        return 1
    fi
}

# Get information about a VirtualBox VM
driver_get_vm_info() {
    local vm_name=$1

    validate_vm_name "$vm_name" || return 1

    VBoxManage showvminfo "$vm_name" 2>/dev/null || return 1
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
