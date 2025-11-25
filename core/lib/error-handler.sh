#!/bin/bash
# Error handling and logging utilities
# Provides consistent error handling, logging, and cleanup mechanisms

# Source colors library if not already sourced
[[ -z "${COLORS_SOURCED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

# Export colors for subshells
export COLORS_SOURCED=true

# Global error tracking
ERRORS_OCCURRED=0
WARNINGS_OCCURRED=0
TEMP_FILES=()
CLEANUP_FUNCTIONS=()

# NOTE: Strict mode (set -euo pipefail) should only be set in executable scripts,
# not in library files. Libraries provide functions that can be sourced safely.

error_handler() {
    local exit_code=$1
    local command=$2
    local filename=$3
    local lineno=$4
    local function_name=$5

    # Don't trigger on success or expected exits
    if [[ $exit_code -eq 0 || $exit_code -eq 130 ]]; then
        return 0
    fi

    ERRORS_OCCURRED=$((ERRORS_OCCURRED + 1))

    print_error "Command failed with exit code $exit_code"
    print_debug "  File: $filename"
    print_debug "  Line: $lineno"
    print_debug "  Function: $function_name"
    print_debug "  Command: $command"

    # Run cleanup before exit
    cleanup_on_error
}

cleanup_on_exit() {
    local exit_code=$?

    # Remove temporary files
    for temp_file in "${TEMP_FILES[@]}"; do
        if [[ -f "$temp_file" ]]; then
            rm -f "$temp_file" 2>/dev/null || true
        fi
    done

    # Run registered cleanup functions
    for cleanup_func in "${CLEANUP_FUNCTIONS[@]}"; do
        if declare -f "$cleanup_func" >/dev/null; then
            "$cleanup_func" 2>/dev/null || true
        fi
    done

    # Exit with the actual exit code
    return "$exit_code"
}

signal_handler() {
    local signal=$1
    print_warning "Received $signal, cleaning up..."
    exit 130
}

# Register a cleanup function to run at exit
register_cleanup() {
    local cleanup_func=$1
    CLEANUP_FUNCTIONS+=("$cleanup_func")
}

# Register a temporary file for cleanup
register_temp_file() {
    local temp_file=$1
    TEMP_FILES+=("$temp_file")
}

# Assert condition is true, otherwise fail with message
assert() {
    local condition=$1
    local message=${2:-"Assertion failed"}

    if ! eval "$condition"; then
        die "$message (condition: $condition)"
    fi
}

# Die with error message
die() {
    local message=$1
    local exit_code=${2:-1}

    print_error "$message"
    exit "$exit_code"
}

# Warn about something but continue
warn() {
    local message=$1

    WARNINGS_OCCURRED=$((WARNINGS_OCCURRED + 1))
    print_warning "$message"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a command exists, die if not
require_command() {
    local command=$1
    local install_hint=${2:-"Please install $command and try again"}

    if ! command_exists "$command"; then
        die "$command not found. $install_hint"
    fi
}

# Check if a file exists, die if not
require_file() {
    local file=$1
    local message=${2:-"Required file not found: $file"}

    if [[ ! -f "$file" ]]; then
        die "$message"
    fi
}

# Check if a directory exists, die if not
require_dir() {
    local dir=$1
    local message=${2:-"Required directory not found: $dir"}

    if [[ ! -d "$dir" ]]; then
        die "$message"
    fi
}

# Run a command with error checking and optional dry-run
run_cmd() {
    local cmd=$1
    local description=${2:-"Running: $cmd"}

    print_info "$description"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        print_debug "  [DRY-RUN] Would execute: $cmd"
        return 0
    fi

    if eval "$cmd"; then
        print_debug "  Command succeeded"
        return 0
    else
        local exit_code=$?
        print_error "Command failed: $cmd"
        return "$exit_code"
    fi
}

# Run a command silently
run_silent() {
    local cmd=$1

    if ! output=$(eval "$cmd" 2>&1); then
        print_debug "Silent command failed: $cmd"
        print_debug "Output: $output"
        return 1
    fi

    echo "$output"
    return 0
}

# Summary of errors and warnings
print_summary() {
    local total_issues=$((ERRORS_OCCURRED + WARNINGS_OCCURRED))

    if [[ $total_issues -eq 0 ]]; then
        print_success "No errors or warnings"
        return 0
    fi

    print_section "Summary"

    if [[ $ERRORS_OCCURRED -gt 0 ]]; then
        print_error "$ERRORS_OCCURRED error(s) occurred"
    fi

    if [[ $WARNINGS_OCCURRED -gt 0 ]]; then
        print_warning "$WARNINGS_OCCURRED warning(s) occurred"
    fi

    return "$ERRORS_OCCURRED"
}

# Export variables for use in subshells
export ERRORS_OCCURRED WARNINGS_OCCURRED
