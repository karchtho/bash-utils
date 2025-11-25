#!/bin/bash
# Auto-Updater with Fail-Safe Rollback
# Manages script updates, backups, and rollback functionality

# Source required libraries
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
source "$SCRIPT_DIR/core/lib/colors.sh"
source "$SCRIPT_DIR/core/lib/error-handler.sh"
source "$SCRIPT_DIR/core/lib/validation.sh"
source "$SCRIPT_DIR/core/lib/common.sh"

# Update configuration
readonly UPDATE_DIR="${HOME}/.vm-scripts/updates"
readonly BACKUP_DIR="${HOME}/.vm-scripts/backups"
readonly UPDATE_LOG="${UPDATE_DIR}/update.log"
readonly VERSION_FILE="$SCRIPT_DIR/.version"
readonly REMOTE_REPO="${REMOTE_REPO:-https://github.com/YOUR_REPO/scripts-bash.git}"

# Initialize update directories
initialize_update_dirs() {
    mkdir -p "$UPDATE_DIR"
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$UPDATE_DIR" "$BACKUP_DIR"

    # Create version file if it doesn't exist
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "1.0.0" > "$VERSION_FILE"
    fi
}

# Get current version
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        echo "1.0.0"
    fi
}

# Check for updates from remote repository
check_for_updates() {
    print_section "Checking for Updates"

    local current_version
    current_version=$(get_current_version)

    print_info "Current version: $current_version"
    print_info "Checking remote repository..."
    echo ""

    # Clone/update remote repository
    local temp_repo="${UPDATE_DIR}/repo-check"

    if [[ -d "$temp_repo" ]]; then
        print_info "Updating existing repository copy..."
        if ! git -C "$temp_repo" pull origin main > /dev/null 2>&1; then
            print_error "Failed to update repository"
            return 1
        fi
    else
        print_info "Cloning repository..."
        if ! git clone "$REMOTE_REPO" "$temp_repo" > /dev/null 2>&1; then
            print_error "Failed to clone repository"
            return 1
        fi
    fi

    # Check for new version
    if [[ -f "$temp_repo/.version" ]]; then
        local remote_version
        remote_version=$(cat "$temp_repo/.version")

        print_info "Remote version: $remote_version"
        echo ""

        if [[ "$remote_version" != "$current_version" ]]; then
            print_ok "Update available: $current_version -> $remote_version"
            return 0
        else
            print_info "Scripts are up to date"
            return 1
        fi
    else
        print_error "Could not determine remote version"
        return 1
    fi
}

# Create backup before update
create_backup() {
    local version=$1
    local backup_path="$BACKUP_DIR/backup-${version}-$(date +%s)"

    print_section "Creating Backup"
    print_info "Backup location: $backup_path"
    echo ""

    # Create backup directory
    mkdir -p "$backup_path"

    # Copy entire script directory
    if cp -r "$SCRIPT_DIR"/* "$backup_path/" 2>/dev/null; then
        # Create backup manifest
        cat > "$backup_path/BACKUP_MANIFEST" << MANIFEST_EOF
Backup Information
==================
Version: $version
Created: $(date '+%Y-%m-%d %H:%M:%S')
Source: $SCRIPT_DIR
Hostname: $(hostname)
User: $(whoami)

Files Backed Up:
$(find "$backup_path" -type f | wc -l) files

To restore this backup, run:
  vm rollback $version

To list all backups, run:
  vm list-backups
MANIFEST_EOF

        print_ok "Backup created successfully"
        echo "$backup_path"
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# List available backups
list_backups() {
    print_section "Available Backups"

    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        print_info "No backups available"
        return 0
    fi

    echo ""
    local count=0
    for backup in "$BACKUP_DIR"/backup-*; do
        if [[ -d "$backup" ]]; then
            ((count++))
            local version
            version=$(grep "^Version:" "$backup/BACKUP_MANIFEST" 2>/dev/null | awk '{print $2}')
            local created
            created=$(grep "^Created:" "$backup/BACKUP_MANIFEST" 2>/dev/null | cut -d: -f2- | xargs)
            local name
            name=$(basename "$backup")

            echo "  [$count] $name"
            echo "      Version: $version"
            echo "      Created: $created"
            echo ""
        fi
    done

    if [[ $count -eq 0 ]]; then
        print_info "No backups available"
    fi

    return 0
}

# Verify backup integrity
verify_backup() {
    local backup_path=$1

    print_section "Verifying Backup Integrity"
    print_info "Backup: $(basename "$backup_path")"
    echo ""

    local checks_passed=0
    local checks_total=0

    # Check backup directory exists
    ((checks_total++))
    if [[ -d "$backup_path" ]]; then
        print_ok "Backup directory exists"
        ((checks_passed++))
    else
        print_error "Backup directory not found"
    fi

    # Check manifest exists
    ((checks_total++))
    if [[ -f "$backup_path/BACKUP_MANIFEST" ]]; then
        print_ok "Backup manifest found"
        ((checks_passed++))
    else
        print_error "Backup manifest not found"
    fi

    # Check core files exist
    ((checks_total++))
    if [[ -f "$backup_path/bin/vm" ]]; then
        print_ok "Main script found"
        ((checks_passed++))
    else
        print_error "Main script not found in backup"
    fi

    # Check libraries exist
    ((checks_total++))
    if [[ -d "$backup_path/core/lib" ]] && [[ -f "$backup_path/core/lib/colors.sh" ]]; then
        print_ok "Core libraries found"
        ((checks_passed++))
    else
        print_error "Core libraries not found in backup"
    fi

    echo ""
    print_info "Verification: $checks_passed/$checks_total checks passed"

    if [[ $checks_passed -eq $checks_total ]]; then
        print_ok "Backup is valid"
        return 0
    else
        print_error "Backup verification failed"
        return 1
    fi
}

# Rollback to previous version
rollback_to_backup() {
    local backup_path=$1

    if [[ ! -d "$backup_path" ]]; then
        print_error "Backup not found: $backup_path"
        return 1
    fi

    print_section "Rolling Back to Backup"
    print_warning "This will restore all scripts from backup"
    echo ""

    # Verify backup before rollback
    if ! verify_backup "$backup_path"; then
        print_error "Backup verification failed - rollback cancelled"
        return 1
    fi

    echo ""
    print_warning "Proceeding with rollback..."
    echo ""

    # Create temporary copy for safety
    local temp_current="${UPDATE_DIR}/current-before-rollback-$(date +%s)"
    mkdir -p "$temp_current"

    if ! cp -r "$SCRIPT_DIR"/* "$temp_current/" 2>/dev/null; then
        print_error "Failed to create safety copy"
        return 1
    fi

    # Perform rollback
    if rm -rf "$SCRIPT_DIR"/* && cp -r "$backup_path"/* "$SCRIPT_DIR/"; then
        print_ok "Rollback completed successfully"

        # Update version
        local version
        version=$(grep "^Version:" "$backup_path/BACKUP_MANIFEST" | awk '{print $2}')
        if [[ -n "$version" ]]; then
            echo "$version" > "$VERSION_FILE"
        fi

        # Log rollback
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Rollback performed"
            echo "  Backup: $(basename "$backup_path")"
            echo "  Version: $version"
            echo "  Status: SUCCESS"
        } >> "$UPDATE_LOG"

        print_info "Version updated to: $(get_current_version)"
        return 0
    else
        print_error "Rollback failed - safety copy preserved at: $temp_current"
        return 1
    fi
}

# Perform update
perform_update() {
    print_section "Performing Update"

    local current_version
    current_version=$(get_current_version)

    print_info "Current version: $current_version"
    echo ""

    # Create backup first
    local backup_path
    backup_path=$(create_backup "$current_version")
    if [[ -z "$backup_path" ]]; then
        print_error "Backup creation failed - update cancelled"
        return 1
    fi

    echo ""

    # Update from repository
    local temp_repo="${UPDATE_DIR}/repo-update"

    if [[ -d "$temp_repo" ]]; then
        print_info "Updating from repository..."
        if ! git -C "$temp_repo" pull origin main > /dev/null 2>&1; then
            print_error "Failed to update repository"
            print_warning "Rolling back due to update failure..."
            rollback_to_backup "$backup_path"
            return 1
        fi
    else
        print_info "Cloning repository for update..."
        if ! git clone "$REMOTE_REPO" "$temp_repo" > /dev/null 2>&1; then
            print_error "Failed to clone repository"
            print_warning "Rolling back due to clone failure..."
            rollback_to_backup "$backup_path"
            return 1
        fi
    fi

    # Get new version
    local new_version
    if [[ -f "$temp_repo/.version" ]]; then
        new_version=$(cat "$temp_repo/.version")
    else
        new_version="unknown"
    fi

    # Copy updated files
    print_info "Installing update..."
    if cp -r "$temp_repo"/* "$SCRIPT_DIR/"; then
        echo "$new_version" > "$VERSION_FILE"

        # Log update
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Update performed"
            echo "  From version: $current_version"
            echo "  To version: $new_version"
            echo "  Backup: $(basename "$backup_path")"
            echo "  Status: SUCCESS"
        } >> "$UPDATE_LOG"

        print_ok "Update completed successfully"
        print_ok "Updated to version: $new_version"
        echo ""
        print_info "Backup location: $backup_path"
        echo ""

        return 0
    else
        print_error "Failed to copy updated files"
        print_warning "Rolling back due to installation failure..."
        rollback_to_backup "$backup_path"
        return 1
    fi
}

# View update log
view_update_log() {
    print_section "Update Log"

    if [[ ! -f "$UPDATE_LOG" ]]; then
        print_info "No update history available"
        return 0
    fi

    echo ""
    cat "$UPDATE_LOG"
    echo ""

    return 0
}

# Cleanup old backups (keep last N)
cleanup_old_backups() {
    local keep_count=${1:-5}

    print_section "Cleaning Up Old Backups"
    print_info "Keeping latest $keep_count backups..."
    echo ""

    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_info "No backups to clean"
        return 0
    fi

    local backup_count
    backup_count=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)

    if [[ $backup_count -le $keep_count ]]; then
        print_info "Current backups: $backup_count (threshold: $keep_count)"
        return 0
    fi

    # Remove oldest backups
    local remove_count=$((backup_count - keep_count))
    print_info "Removing $remove_count old backup(s)..."

    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | \
    sort -n | head -n "$remove_count" | cut -d' ' -f2- | \
    while read -r old_backup; do
        print_info "Removing: $(basename "$old_backup")"
        rm -rf "$old_backup"
    done

    print_ok "Cleanup completed"
    echo ""

    return 0
}

# Initialize on first run
initialize_update_dirs

# Export functions
export -f initialize_update_dirs
export -f get_current_version
export -f check_for_updates
export -f create_backup
export -f list_backups
export -f verify_backup
export -f rollback_to_backup
export -f perform_update
export -f view_update_log
export -f cleanup_old_backups
