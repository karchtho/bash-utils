#!/bin/bash
# Hypervisor Interface Definition
# All hypervisor drivers must implement these functions
# This is an abstract interface that defines the contract for all drivers

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Abstract function - creates a new VM
# Arguments:
#   $1 - VM name
#   $2 - CPU count
#   $3 - Memory (e.g., "4G", "512M")
#   $4 - Disk size (e.g., "15G")
#   $5 - Base image (e.g., "ubuntu:24.04")
# Returns: 0 on success, 1 on failure
driver_create_vm() {
    local vm_name=$1
    local cpus=$2
    local memory=$3
    local disk=$4
    local image=$5

    die "driver_create_vm() not implemented in this driver"
}

# Abstract function - starts a stopped VM
# Arguments:
#   $1 - VM name
# Returns: 0 on success, 1 on failure
driver_start_vm() {
    local vm_name=$1

    die "driver_start_vm() not implemented in this driver"
}

# Abstract function - stops a running VM
# Arguments:
#   $1 - VM name
# Returns: 0 on success, 1 on failure
driver_stop_vm() {
    local vm_name=$1

    die "driver_stop_vm() not implemented in this driver"
}

# Abstract function - deletes a VM
# Arguments:
#   $1 - VM name
# Returns: 0 on success, 1 on failure
driver_delete_vm() {
    local vm_name=$1

    die "driver_delete_vm() not implemented in this driver"
}

# Abstract function - executes a command in a VM
# Arguments:
#   $1 - VM name
#   $2+ - Command and arguments to execute
# Returns: 0 on success, 1 on failure
driver_exec_command() {
    local vm_name=$1
    shift
    local -a command=("$@")

    die "driver_exec_command() not implemented in this driver"
}

# Abstract function - lists all VMs
# Output: One VM name per line
# Returns: 0 on success, 1 on failure
driver_list_vms() {
    die "driver_list_vms() not implemented in this driver"
}

# Abstract function - gets VM status
# Arguments:
#   $1 - VM name
# Output: One of: running, stopped, not-found, error
# Returns: 0 on success, 1 on failure
driver_get_vm_status() {
    local vm_name=$1

    die "driver_get_vm_status() not implemented in this driver"
}

# Abstract function - gets VM IP address
# Arguments:
#   $1 - VM name
# Output: IP address (or empty if not available)
# Returns: 0 on success, 1 on failure
driver_get_vm_ip() {
    local vm_name=$1

    die "driver_get_vm_ip() not implemented in this driver"
}

# Abstract function - mounts a local directory in VM
# Arguments:
#   $1 - VM name
#   $2 - Local path
#   $3 - VM mount path
# Returns: 0 on success, 1 on failure
driver_mount_directory() {
    local vm_name=$1
    local local_path=$2
    local vm_path=$3

    die "driver_mount_directory() not implemented in this driver"
}

# Abstract function - gets VM information
# Arguments:
#   $1 - VM name
# Output: JSON or formatted string with VM info
# Returns: 0 on success, 1 on failure
driver_get_vm_info() {
    local vm_name=$1

    die "driver_get_vm_info() not implemented in this driver"
}

# Abstract function - checks if hypervisor is installed
# Output: "true" or "false"
# Returns: 0 always
driver_is_available() {
    die "driver_is_available() not implemented in this driver"
}

# Abstract function - gets hypervisor version
# Output: Version string
# Returns: 0 on success, 1 on failure
driver_get_version() {
    die "driver_get_version() not implemented in this driver"
}

# Validation function - ensures all required functions are implemented
validate_driver_implementation() {
    local driver_name=$1

    local required_functions=(
        "driver_create_vm"
        "driver_start_vm"
        "driver_stop_vm"
        "driver_delete_vm"
        "driver_exec_command"
        "driver_list_vms"
        "driver_get_vm_status"
        "driver_get_vm_ip"
        "driver_mount_directory"
        "driver_get_vm_info"
        "driver_is_available"
        "driver_get_version"
    )

    local missing_functions=()

    for func in "${required_functions[@]}"; do
        if ! declare -f "$func" >/dev/null; then
            missing_functions+=("$func")
        fi
    done

    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        print_error "$driver_name is missing required functions:"
        for func in "${missing_functions[@]}"; do
            print_error "  - $func"
        done
        return 1
    fi

    return 0
}

# Utility function - run command with optional dry-run support
driver_run_cmd() {
    local description=$1
    shift
    local -a cmd=("$@")

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_info "[DRY-RUN] $description"
        print_debug "Would execute: ${cmd[*]}"
        return 0
    fi

    print_info "$description"
    if "${cmd[@]}"; then
        return 0
    else
        local exit_code=$?
        print_error "Failed: $description"
        return "$exit_code"
    fi
}

# Utility function - wait for VM to have IP address
driver_wait_for_ip() {
    local vm_name=$1
    local timeout=${2:-300}  # 5 minutes default
    local interval=${3:-2}

    print_info "Waiting for VM to get IP address (timeout: ${timeout}s)..."

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        local ip
        ip=$(driver_get_vm_ip "$vm_name" 2>/dev/null || echo "")

        if [[ -n "$ip" && "$ip" != "N/A" && "$ip" != "Unknown" ]]; then
            print_ok "VM IP address: $ip"
            echo "$ip"
            return 0
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
        printf "."
    done

    printf "\n"
    print_error "Timeout waiting for VM IP address"
    return 1
}

# Export abstract functions for use in drivers
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
export -f driver_is_available
export -f driver_get_version
export -f validate_driver_implementation
export -f driver_run_cmd
export -f driver_wait_for_ip
