#!/bin/bash
# Tool Selection Menu System
# Provides interactive multi-select menu for development tools

# Source required libraries
# Calculate base directory from this script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

source "${SCRIPT_DIR}/core/lib/colors.sh"
source "${SCRIPT_DIR}/core/lib/error-handler.sh"
source "${SCRIPT_DIR}/core/lib/validation.sh"
source "${SCRIPT_DIR}/core/lib/common.sh"

# Source tool installers
source "${SCRIPT_DIR}/core/tools/lamp-installer.sh"
source "${SCRIPT_DIR}/core/tools/nodejs-installer.sh"
source "${SCRIPT_DIR}/core/tools/python-installer.sh"
source "${SCRIPT_DIR}/core/tools/angular-installer.sh"

# Tool definitions
declare -A TOOLS=(
    [lamp]="LAMP Stack (Apache, MySQL, PHP)"
    [nodejs]="Node.js and npm (LTS)"
    [python]="Python3 with venv"
    [angular]="Angular (requires Node.js)"
)

# Tool dependencies
declare -A TOOL_DEPS=(
    [lamp]=""
    [nodejs]=""
    [python]=""
    [angular]="nodejs"
)

# Tool installers
declare -A TOOL_INSTALLERS=(
    [lamp]="install_lamp"
    [nodejs]="install_nodejs"
    [python]="install_python"
    [angular]="install_angular_cli"
)

# Display tool selection menu
show_tool_menu() {
    print_section "Development Tools Selection"
    print_info "Select tools to install (space to toggle, Enter to continue):"
    echo ""

    local -a tool_list=()
    local -a tool_names=()

    # Build tool list
    for tool in lamp nodejs python angular; do
        tool_list+=("$tool")
        tool_names+=("${TOOLS[$tool]}")
    done

    # Simple menu without fzf (fallback)
    local -i index=0
    local -a selected=()

    while true; do
        clear
        print_section "Development Tools Selection"
        echo ""

        for i in "${!tool_list[@]}"; do
            local tool="${tool_list[$i]}"
            local name="${tool_names[$i]}"
            local marker="[ ]"

            # Check if selected
            if array_contains "$tool" "${selected[@]}" 2>/dev/null; then
                marker="[✓]"
            fi

            if [[ $i -eq $index ]]; then
                echo -e "  ${BLUE}${marker} ${name}${NC}"
            else
                echo "  $marker $name"
            fi
        done

        echo ""
        echo "  ${YELLOW}↑↓${NC} Navigate  ${YELLOW}Space${NC} Toggle  ${YELLOW}Enter${NC} Continue  ${YELLOW}Q${NC} Quit"
        echo ""

        read -rsn1 input
        case "$input" in
            '')  # Enter
                break
                ;;
            ' ')  # Space to toggle
                local tool="${tool_list[$index]}"
                if array_contains "$tool" "${selected[@]}" 2>/dev/null; then
                    # Remove from selected
                    local new_selected=()
                    for s in "${selected[@]}"; do
                        [[ "$s" != "$tool" ]] && new_selected+=("$s")
                    done
                    selected=("${new_selected[@]}")
                else
                    # Add to selected
                    selected+=("$tool")
                fi
                ;;
            $'A'|$'B')  # Arrow keys
                if [[ "$input" == $'A' ]]; then
                    ((index--))
                    [[ $index -lt 0 ]] && index=$((${#tool_list[@]} - 1))
                else
                    ((index++))
                    [[ $index -ge ${#tool_list[@]} ]] && index=0
                fi
                ;;
            [Qq])
                print_warning "Installation cancelled"
                return 1
                ;;
        esac
    done

    echo "${selected[@]}"
    return 0
}

# Simpler text-based menu (non-interactive)
show_tool_menu_simple() {
    print_section "Development Tools Selection"
    echo ""

    local -a tool_list=()
    for tool in lamp nodejs python angular; do
        tool_list+=("$tool")
    done

    echo "Available tools:"
    for i in "${!tool_list[@]}"; do
        local tool="${tool_list[$i]}"
        local name="${TOOLS[$tool]}"
        echo "  $((i+1)). $name"
    done

    echo ""
    echo "Enter tool numbers to install (comma-separated, e.g. 1,2,3):"
    read -r selection

    local -a selected=()
    IFS=',' read -ra selections <<< "$selection"

    for sel in "${selections[@]}"; do
        sel=$(trim "$sel")
        if [[ "$sel" =~ ^[0-9]+$ ]]; then
            local index=$((sel - 1))
            if [[ $index -ge 0 && $index -lt ${#tool_list[@]} ]]; then
                selected+=("${tool_list[$index]}")
            fi
        fi
    done

    # Remove duplicates
    selected=($(array_unique "${selected[@]}"))

    echo "${selected[@]}"
    return 0
}

# Install selected tools
install_selected_tools() {
    local -a selected=("$@")

    if [[ ${#selected[@]} -eq 0 ]]; then
        print_info "No tools selected"
        return 0
    fi

    print_section "Installing Selected Tools"
    echo ""

    local -i success_count=0
    local -i fail_count=0

    for tool in "${selected[@]}"; do
        echo ""

        # Validate tool exists
        if [[ -z "${TOOLS[$tool]:-}" ]]; then
            print_error "Unknown tool: $tool"
            ((fail_count++))
            continue
        fi

        print_subsection "Installing: ${TOOLS[$tool]}"

        # Check dependencies
        local deps="${TOOL_DEPS[$tool]:-}"
        if [[ -n "$deps" ]]; then
            print_info "Checking dependencies: $deps"
            if ! verify_tool_installed "$deps"; then
                print_error "$tool requires $deps to be installed first"
                ((fail_count++))
                continue
            fi
        fi

        # Run installer
        local installer="${TOOL_INSTALLERS[$tool]}"
        if $installer; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Summary
    echo ""
    print_section "Installation Summary"
    echo -e "  Successful: ${GREEN}$success_count${NC}"
    echo -e "  Failed:     ${RED}$fail_count${NC}"
    echo ""

    if [[ $fail_count -eq 0 ]]; then
        print_ok "All tools installed successfully"
        return 0
    else
        print_warning "Some tools failed to install"
        return 1
    fi
}

# Verify if a tool is installed
verify_tool_installed() {
    local tool=$1

    case "$tool" in
        lamp)
            command_exists apache2
            ;;
        nodejs)
            command_exists node
            ;;
        python)
            command_exists python3
            ;;
        angular)
            command_exists ng
            ;;
        *)
            print_error "Unknown tool: $tool"
            return 1
            ;;
    esac
}

# Verify all selected tools
verify_all_tools() {
    local -a selected=("$@")

    if [[ ${#selected[@]} -eq 0 ]]; then
        return 0
    fi

    print_section "Verifying Installations"
    echo ""

    for tool in "${selected[@]}"; do
        if verify_tool_installed "$tool"; then
            print_ok "$tool is installed"
        else
            print_warning "$tool is not installed"
        fi
    done

    echo ""
    return 0
}

# Export functions
export -f show_tool_menu
export -f show_tool_menu_simple
export -f install_selected_tools
export -f verify_tool_installed
export -f verify_all_tools
