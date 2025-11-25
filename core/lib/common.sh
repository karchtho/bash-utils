#!/bin/bash
# Common utilities and helper functions
# Shared across all scripts in the system

# Source required libraries (if not already loaded)
# These should be sourced in order: colors -> error-handler -> validation -> common
# If they're already loaded, we skip re-sourcing them
[[ -z "${COLORS_SOURCED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
[[ -z "${ERROR_HANDLER_SOURCED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/error-handler.sh"
[[ -z "${VALIDATION_SOURCED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/validation.sh"

# Export markers for subshells
export COLORS_SOURCED=true
export ERROR_HANDLER_SOURCED=true
export VALIDATION_SOURCED=true

# Get the root project directory
get_root_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)" 2>/dev/null || echo ""
}

# Initialize ROOT_DIR only if not already set
if [[ -z "${ROOT_DIR:-}" ]]; then
    ROOT_DIR=$(get_root_dir)
fi
export ROOT_DIR

# Get absolute path of a file/directory
get_absolute_path() {
    local path=$1

    if [[ "$path" = /* ]]; then
        echo "$path"
    else
        echo "$(cd "$path" 2>/dev/null && pwd)" || echo "$PWD/$path"
    fi
}

# Get relative path between two directories
get_relative_path() {
    local from=$1
    local to=$2

    python3 -c "import os.path; print(os.path.relpath('$to', '$from'))"
}

# Check if running inside a virtual machine (Multipass or VirtualBox)
is_in_vm() {
    # Check for common VM identifiers
    [[ -f /sys/class/dmi/id/system_uuid ]] && grep -qi "^cbef" /sys/class/dmi/id/system_uuid && return 0
    [[ -f /sys/class/dmi/id/chassis_asset_tag ]] && grep -qi "multipass" /sys/class/dmi/id/chassis_asset_tag && return 0
    [[ -f /.dockerenv ]] && return 0

    # Check for environment variable (set by our VM setup)
    [[ -n "${MULTIPASS_VM_NAME:-}" ]] && return 0

    return 1
}

# Detect which hypervisor is running on this system
detect_hypervisors() {
    local -a available_hypervisors=()

    if command_exists multipass; then
        available_hypervisors+=("multipass")
    fi

    if command_exists VBoxManage; then
        available_hypervisors+=("virtualbox")
    fi

    if command_exists virsh; then
        available_hypervisors+=("libvirt")
    fi

    if command_exists virsh || command_exists qemu-system-x86_64; then
        available_hypervisors+=("kvm")
    fi

    if [[ -e /proc/xen ]]; then
        available_hypervisors+=("xen")
    fi

    # Output as space-separated list
    echo "${available_hypervisors[@]}"
}

# Check if a specific hypervisor is available
has_hypervisor() {
    local hypervisor=$1
    local available

    available=$(detect_hypervisors)

    for hv in $available; do
        if [[ "$hv" == "$hypervisor" ]]; then
            return 0
        fi
    done

    return 1
}

# Check if a command exists in PATH
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if user has sudo privileges
has_sudo() {
    sudo -n true 2>/dev/null
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Get current OS
get_os() {
    case "$(uname -s)" in
        Linux*) echo "linux" ;;
        Darwin*) echo "macos" ;;
        MINGW*|MSYS*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

# Get Linux distribution
get_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}"
    else
        echo "unknown"
    fi
}

# Pause with optional message
pause() {
    local message=${1:-"Press any key to continue..."}
    print_input_prompt "$message"
    read -r -s -n 1
    echo ""
}

# Create spinner for long operations
spinner() {
    local pid=$1
    local message=${2:-"Processing"}

    local -a spinner_chars=('|' '/' '-' '\')
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${spinner_chars[$((i % ${#spinner_chars[@]}))]]} $message"
        ((i++))
        sleep 0.1
    done

    printf "\r"
}

# Run a function with timeout
with_timeout() {
    local timeout_seconds=$1
    shift
    local -a cmd=("$@")

    # Run command in background
    "${cmd[@]}" &
    local pid=$!

    # Wait for command or timeout
    ( sleep "$timeout_seconds" && kill "$pid" 2>/dev/null ) &
    local killer=$!

    if wait "$pid" 2>/dev/null; then
        kill "$killer" 2>/dev/null || true
        return 0
    else
        local exit_code=$?
        kill "$killer" 2>/dev/null || true
        return "$exit_code"
    fi
}

# Compare version numbers
version_greater_equal() {
    local version1=$1
    local version2=$2

    [[ "$version1" == "$version2" ]] && return 0

    local IFS=.
    local -a v1_parts=($version1)
    local -a v2_parts=($version2)

    for ((i = 0; i < ${#v1_parts[@]} || i < ${#v2_parts[@]}; i++)); do
        local v1=${v1_parts[$i]:-0}
        local v2=${v2_parts[$i]:-0}

        [[ ! $v1 =~ ^[0-9]+$ ]] && v1=0
        [[ ! $v2 =~ ^[0-9]+$ ]] && v2=0

        if ((v1 > v2)); then
            return 0
        elif ((v1 < v2)); then
            return 1
        fi
    done

    return 0
}

# Create a backup of a file
backup_file() {
    local file=$1
    local backup_dir=${2:-".backups"}

    if [[ ! -f "$file" ]]; then
        print_warning "File not found for backup: $file"
        return 1
    fi

    mkdir -p "$backup_dir"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename
    filename=$(basename "$file")
    local backup_file="$backup_dir/${filename}.${timestamp}.bak"

    if cp "$file" "$backup_file"; then
        print_ok "Backed up: $file → $backup_file"
        echo "$backup_file"
        return 0
    else
        print_error "Failed to backup: $file"
        return 1
    fi
}

# Restore from backup
restore_file() {
    local backup_file=$1
    local target_file=${2:-}

    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi

    # Extract original filename if target not specified
    if [[ -z "$target_file" ]]; then
        target_file="${backup_file%.*}"
        # Remove timestamp if it matches pattern
        target_file="${target_file%.*}"
    fi

    if cp "$backup_file" "$target_file"; then
        print_ok "Restored: $target_file from $backup_file"
        return 0
    else
        print_error "Failed to restore: $target_file"
        return 1
    fi
}

# Join array elements with separator
join_array() {
    local separator=$1
    shift
    local -a array=("$@")

    local IFS="$separator"
    echo "${array[*]}"
}

# Split string into array
split_string() {
    local string=$1
    local separator=${2:-,}

    local IFS="$separator"
    read -ra parts <<< "$string"
    printf '%s\n' "${parts[@]}"
}

# Trim whitespace from string
trim() {
    local string=$1
    string="${string#"${string%%[![:space:]]*}"}"
    string="${string%"${string##*[![:space:]]}"}"
    echo "$string"
}

# Convert string to lowercase
to_lower() {
    echo "${1,,}"
}

# Convert string to uppercase
to_upper() {
    echo "${1^^}"
}

# Check if array contains element
array_contains() {
    local element=$1
    shift
    local -a array=("$@")

    for item in "${array[@]}"; do
        [[ "$item" == "$element" ]] && return 0
    done

    return 1
}

# Get unique elements from array
array_unique() {
    local -a array=("$@")
    local -a unique

    for item in "${array[@]}"; do
        if ! array_contains "$item" "${unique[@]}"; then
            unique+=("$item")
        fi
    done

    printf '%s\n' "${unique[@]}"
}

# Calculate file hash
get_file_hash() {
    local file=$1

    if [[ ! -f "$file" ]]; then
        print_error "File not found: $file"
        return 1
    fi

    if command_exists sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    elif command_exists shasum; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        print_error "No hashing utility found (sha256sum or shasum)"
        return 1
    fi
}

# Log message to file
log_message() {
    local message=$1
    local log_file=${2:-"$ROOT_DIR/scripts.log"}

    mkdir -p "$(dirname "$log_file")"

    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] $message" >> "$log_file"
}

# Print formatted list
print_list() {
    local title=${1:-"Items"}
    shift
    local -a items=("$@")

    print_subsection "$title"
    for item in "${items[@]}"; do
        echo "  $DOT $item"
    done
    echo ""
}

# Pretty print JSON (requires jq)
pretty_json() {
    local json=$1

    if command_exists jq; then
        echo "$json" | jq '.'
    else
        echo "$json"
    fi
}

# Export all functions for subshells
export -f is_in_vm
export -f detect_hypervisors
export -f has_hypervisor
export -f command_exists
export -f has_sudo
export -f is_root
export -f get_os
export -f get_linux_distro
export -f pause
export -f spinner
export -f with_timeout
export -f version_greater_equal
export -f backup_file
export -f restore_file
export -f join_array
export -f split_string
export -f trim
export -f to_lower
export -f to_upper
export -f array_contains
export -f array_unique
export -f get_file_hash
export -f log_message
export -f print_list
export -f pretty_json
export -f get_absolute_path
export -f get_relative_path
export -f get_root_dir
