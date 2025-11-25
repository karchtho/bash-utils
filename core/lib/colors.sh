#!/bin/bash
# Color definitions and formatting utilities
# Used throughout the script system for consistent colored output

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Background colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'

# Text styles
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
REVERSE='\033[7m'

# Emoji/Unicode symbols (for systems that support them)
CHECKMARK='✓'
CROSS='✗'
ARROW='→'
DOT='•'
STAR='★'
CLOCK='⏱'
GEAR='⚙'
BOLT='⚡'

# Output formatting functions
print_section() {
    echo -e "\n${BLUE}${BOLD}======== $1 ========${NC}\n"
}

print_subsection() {
    echo -e "${CYAN}${BOLD}--- $1 ---${NC}"
}

print_ok() {
    echo -e "${GREEN}${CHECKMARK}${NC} $1"
}

print_error() {
    echo -e "${RED}${CROSS}${NC} ${RED}ERROR: $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}${BOLD}⚠${NC}  $1"
}

print_info() {
    echo -e "${BLUE}${BOLD}ℹ${NC}  $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}✓ $1${NC}"
}

print_input_prompt() {
    echo -ne "${CYAN}${BOLD}→ $1${NC} "
}

print_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${GRAY}[DEBUG] $1${NC}" >&2
    fi
}

# Separator line
print_separator() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Table header
print_table_header() {
    echo -e "${BOLD}${CYAN}$1${NC}"
    print_separator
}
