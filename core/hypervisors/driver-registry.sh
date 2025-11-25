#!/bin/bash
# Hypervisor Driver Registry
# Detects available hypervisors, loads drivers, and manages driver selection

# Source required files
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/hypervisor-interface.sh"

DRIVERS_DIR="$(dirname "${BASH_SOURCE[0]}")"
REGISTERED_DRIVERS=()
LOADED_DRIVER=""

# Register a driver
register_driver() {
    local driver_name=$1
    local driver_file=$2

    if [[ -f "$driver_file" ]]; then
        REGISTERED_DRIVERS+=("$driver_name:$driver_file")
        print_debug "Registered driver: $driver_name ($driver_file)"
        return 0
    else
        print_warning "Driver file not found: $driver_file"
        return 1
    fi
}

# Auto-discover and register available drivers
auto_discover_drivers() {
    print_info "Discovering available hypervisor drivers..."

    # Register all available drivers
    register_driver "multipass" "$DRIVERS_DIR/multipass-driver.sh"
    register_driver "virtualbox" "$DRIVERS_DIR/virtualbox-driver.sh"
    register_driver "hyper-v" "$DRIVERS_DIR/hyper-v-driver.sh"
    register_driver "libvirt" "$DRIVERS_DIR/libvirt-driver.sh"

    # Filter to only installed hypervisors
    local -a available_drivers=()

    for driver_entry in "${REGISTERED_DRIVERS[@]}"; do
        local driver_name="${driver_entry%:*}"
        local driver_file="${driver_entry#*:}"

        # Check if driver file exists and hypervisor is available
        if [[ -f "$driver_file" ]]; then
            # Source the driver file to check if it's available
            if source "$driver_file" 2>/dev/null; then
                if driver_is_available; then
                    available_drivers+=("$driver_name")
                    print_debug "Driver available: $driver_name"
                fi
            fi
        fi
    done

    # Return available drivers
    printf '%s\n' "${available_drivers[@]}"
}

# Get path to a specific driver file
get_driver_path() {
    local driver_name=$1

    for driver_entry in "${REGISTERED_DRIVERS[@]}"; do
        if [[ "${driver_entry%:*}" == "$driver_name" ]]; then
            echo "${driver_entry#*:}"
            return 0
        fi
    done

    return 1
}

# Load a specific driver
load_driver() {
    local driver_name=$1

    if [[ -z "$driver_name" ]]; then
        print_error "Driver name not specified"
        return 1
    fi

    local driver_path
    driver_path=$(get_driver_path "$driver_name") || {
        print_error "Driver not found: $driver_name"
        return 1
    }

    if [[ ! -f "$driver_path" ]]; then
        print_error "Driver file not found: $driver_path"
        return 1
    fi

    print_info "Loading driver: $driver_name"

    if source "$driver_path"; then
        if validate_driver_implementation "$driver_name"; then
            LOADED_DRIVER="$driver_name"
            print_ok "Driver loaded: $driver_name"
            return 0
        else
            print_error "Driver validation failed: $driver_name"
            return 1
        fi
    else
        print_error "Failed to load driver: $driver_name"
        return 1
    fi
}

# Get the currently loaded driver
get_loaded_driver() {
    echo "$LOADED_DRIVER"
}

# Check if a driver is loaded
is_driver_loaded() {
    [[ -n "$LOADED_DRIVER" ]]
}

# List all registered drivers
list_registered_drivers() {
    local -a drivers
    mapfile -t drivers < <(auto_discover_drivers)

    if [[ ${#drivers[@]} -eq 0 ]]; then
        print_warning "No hypervisors detected"
        return 1
    fi

    print_subsection "Available Hypervisors"
    for driver in "${drivers[@]}"; do
        echo "  $DOT $driver"
    done
    echo ""

    return 0
}

# Interactive driver selection
select_driver() {
    local -a drivers
    mapfile -t drivers < <(auto_discover_drivers)

    if [[ ${#drivers[@]} -eq 0 ]]; then
        print_error "No hypervisors detected. Please install Multipass or VirtualBox."
        return 1
    fi

    if [[ ${#drivers[@]} -eq 1 ]]; then
        print_info "Only one hypervisor detected: ${drivers[0]}"
        load_driver "${drivers[0]}"
        return $?
    fi

    # Multiple hypervisors available, let user choose
    print_section "Select Hypervisor"
    for i in "${!drivers[@]}"; do
        echo "$((i + 1))) ${drivers[$i]}"
    done
    echo ""

    print_input_prompt "Enter number (1-${#drivers[@]}): "
    read -r choice

    if ! validate_number_range "$choice" 1 "${#drivers[@]}" "Selection"; then
        return 1
    fi

    local selected_driver="${drivers[$((choice - 1))]}"
    load_driver "$selected_driver"
}

# Get driver from configuration file
get_driver_from_config() {
    local config_file=$1

    if [[ ! -f "$config_file" ]]; then
        print_debug "Config file not found: $config_file"
        return 1
    fi

    # Source the config file to get HYPERVISOR variable
    # Use subshell to avoid polluting current environment
    (
        source "$config_file" 2>/dev/null
        echo "${HYPERVISOR:-}"
    )
}

# Ensure driver is loaded and ready
ensure_driver_loaded() {
    local preferred_driver=${1:-}

    if is_driver_loaded; then
        return 0
    fi

    if [[ -n "$preferred_driver" ]]; then
        print_info "Loading preferred driver: $preferred_driver"
        load_driver "$preferred_driver" && return 0
    fi

    # Try to load from config
    local config_file="$ROOT_DIR/config/hypervisor.conf"
    if [[ -f "$config_file" ]]; then
        local config_driver
        config_driver=$(get_driver_from_config "$config_file")
        if [[ -n "$config_driver" ]]; then
            print_info "Loading driver from config: $config_driver"
            load_driver "$config_driver" && return 0
        fi
    fi

    # Auto-select a driver
    print_info "Auto-selecting hypervisor driver..."
    select_driver
}

# Get information about a driver
get_driver_info() {
    local driver_name=$1

    # Load the driver temporarily
    local original_driver="$LOADED_DRIVER"
    load_driver "$driver_name" || return 1

    print_section "Driver: $driver_name"

    local version
    version=$(driver_get_version 2>/dev/null || echo "N/A")
    print_info "Version: $version"

    print_info "Status: Available"

    # Restore original driver
    if [[ -n "$original_driver" ]]; then
        load_driver "$original_driver" >/dev/null 2>&1
    fi
}

# Export registry functions
export -f register_driver
export -f auto_discover_drivers
export -f get_driver_path
export -f load_driver
export -f get_loaded_driver
export -f is_driver_loaded
export -f list_registered_drivers
export -f select_driver
export -f get_driver_from_config
export -f ensure_driver_loaded
export -f get_driver_info
