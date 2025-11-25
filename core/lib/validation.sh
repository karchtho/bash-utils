#!/bin/bash
# Input validation and sanitization utilities
# Provides functions for validating various input types

# Source colors library if not already sourced
[[ -z "$COLORS_SOURCED" ]] && source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Validate variable name format (alphanumeric, underscores, no leading digits)
validate_identifier() {
    local value=$1
    local field_name=${2:-"identifier"}

    if [[ ! $value =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        print_error "$field_name must be alphanumeric with underscores (no leading digits): '$value'"
        return 1
    fi

    return 0
}

# Validate VM name format
validate_vm_name() {
    local vm_name=$1

    # VM names typically allow alphanumeric, hyphens, underscores
    if [[ ! $vm_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "VM name must contain only alphanumeric characters, hyphens, and underscores: '$vm_name'"
        return 1
    fi

    if [[ ${#vm_name} -gt 63 ]]; then
        print_error "VM name is too long (max 63 characters)"
        return 1
    fi

    if [[ ${#vm_name} -lt 2 ]]; then
        print_error "VM name is too short (min 2 characters)"
        return 1
    fi

    return 0
}

# Validate IP address format
validate_ip_address() {
    local ip=$1

    if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        print_error "Invalid IP address format: '$ip'"
        return 1
    fi

    # Check each octet is 0-255
    local IFS='.'
    local -a octets=($ip)
    for octet in "${octets[@]}"; do
        if [[ $octet -gt 255 ]]; then
            print_error "IP address octet out of range (0-255): $octet"
            return 1
        fi
    done

    return 0
}

# Validate email format
validate_email() {
    local email=$1

    if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid email format: '$email'"
        return 1
    fi

    return 0
}

# Validate domain name format
validate_domain() {
    local domain=$1

    if [[ ! $domain =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]] && \
       [[ ! $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        print_error "Invalid domain name format: '$domain'"
        return 1
    fi

    return 0
}

# Validate file path exists and is readable
validate_readable_file() {
    local file=$1
    local description=${2:-"File"}

    if [[ ! -f "$file" ]]; then
        print_error "$description not found: '$file'"
        return 1
    fi

    if [[ ! -r "$file" ]]; then
        print_error "$description is not readable: '$file'"
        return 1
    fi

    return 0
}

# Validate directory path exists and is accessible
validate_readable_dir() {
    local dir=$1
    local description=${2:-"Directory"}

    if [[ ! -d "$dir" ]]; then
        print_error "$description not found: '$dir'"
        return 1
    fi

    if [[ ! -x "$dir" ]]; then
        print_error "$description is not accessible: '$dir'"
        return 1
    fi

    return 0
}

# Validate directory is writable
validate_writable_dir() {
    local dir=$1
    local description=${2:-"Directory"}

    if [[ ! -d "$dir" ]]; then
        print_error "$description not found: '$dir'"
        return 1
    fi

    if [[ ! -w "$dir" ]]; then
        print_error "$description is not writable: '$dir'"
        return 1
    fi

    return 0
}

# Validate numeric value within range
validate_number_range() {
    local value=$1
    local min=$2
    local max=$3
    local description=${4:-"Value"}

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        print_error "$description must be a number: '$value'"
        return 1
    fi

    if [[ $value -lt $min ]]; then
        print_error "$description is less than minimum ($min): $value"
        return 1
    fi

    if [[ $value -gt $max ]]; then
        print_error "$description is greater than maximum ($max): $value"
        return 1
    fi

    return 0
}

# Validate choice from list of options
validate_choice() {
    local value=$1
    shift
    local -a options=("$@")

    for option in "${options[@]}"; do
        if [[ "$value" == "$option" ]]; then
            return 0
        fi
    done

    print_error "Invalid choice '$value'. Valid options: ${options[*]}"
    return 1
}

# Validate required field is not empty
validate_required() {
    local value=$1
    local field_name=${2:-"Field"}

    if [[ -z "$value" ]]; then
        print_error "$field_name is required"
        return 1
    fi

    return 0
}

# Validate memory specification (e.g., "4G", "512M")
validate_memory_spec() {
    local value=$1

    if [[ ! $value =~ ^[0-9]+([GgMmKk])?$ ]]; then
        print_error "Invalid memory specification: '$value' (use format: 512M, 4G, etc.)"
        return 1
    fi

    return 0
}

# Validate CPU count
validate_cpu_count() {
    local cpus=$1

    if ! validate_number_range "$cpus" 1 128 "CPU count"; then
        return 1
    fi

    return 0
}

# Validate path format (allow relative or absolute)
validate_path() {
    local path=$1
    local allow_relative=${2:-true}

    if [[ -z "$path" ]]; then
        print_error "Path cannot be empty"
        return 1
    fi

    # Check for invalid characters
    if [[ $path =~ [[:cntrl:]] ]]; then
        print_error "Path contains invalid characters: '$path'"
        return 1
    fi

    return 0
}

# Sanitize variable value (remove potentially dangerous characters)
sanitize_var() {
    local value=$1

    # Remove leading/trailing whitespace
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    # Return sanitized value
    echo "$value"
}

# Sanitize filename
sanitize_filename() {
    local filename=$1

    # Replace problematic characters with underscores
    filename="${filename//[[:space:]]/_}"
    filename="${filename//[\\/]/_}"
    filename="${filename//[\"\']/}"

    echo "$filename"
}

# Confirm action with yes/no prompt
confirm() {
    local prompt=$1
    local default=${2:-"n"}

    local response

    while true; do
        if [[ "$default" == "y" ]]; then
            print_input_prompt "$prompt (Y/n)? "
        else
            print_input_prompt "$prompt (y/N)? "
        fi

        read -r response
        response="${response:0:1}"
        response="${response,,}"

        case "$response" in
            y)
                return 0
                ;;
            n)
                return 1
                ;;
            "")
                [[ "$default" == "y" ]] && return 0 || return 1
                ;;
            *)
                print_warning "Please answer 'y' or 'n'"
                ;;
        esac
    done
}

# Multiple choice selection
select_option() {
    local prompt=$1
    shift
    local -a options=("$@")

    print_input_prompt "$prompt\n"

    local i
    for i in "${!options[@]}"; do
        echo "  $((i + 1))) ${options[$i]}"
    done

    echo ""
    print_input_prompt "Enter number (1-${#options[@]}): "
    read -r choice

    if ! validate_number_range "$choice" 1 "${#options[@]}" "Selection"; then
        return 1
    fi

    # Return the selected option (convert 1-indexed to 0-indexed)
    echo "${options[$((choice - 1))]}"
    return 0
}
