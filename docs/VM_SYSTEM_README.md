# VM Management System - Complete Documentation

A comprehensive multi-hypervisor VM management system with integrated development environment setup, React development tooling, and automated updates with rollback capability.

## Table of Contents
1. [Quick Start](#quick-start)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Command Reference](#command-reference)
5. [Development Phases](#development-phases)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Quick Start

### Installation
```bash
chmod +x bin/vm
export PATH="$PATH:$(pwd)/bin"
```

### First Commands
```bash
vm --help              # Show all commands
vm diagnostic          # Check system setup
vm setup-shell         # Install Zsh + Powerlevel10k
vm setup-git-ssh       # Configure SSH and Git
```

## Features

### VM Management (Multipass & VirtualBox)
- **Unified Interface**: Single `vm` command for all hypervisors
- **Auto-Detection**: Automatically selects available hypervisor
- **Full Lifecycle**: Create, start, stop, delete, list VMs
- **Resource Control**: CPU, memory, disk allocation
- **SSH Access**: Direct connections to running VMs
- **File Mounting**: Sync directories between host and VM

### Development Tools
- **LAMP Stack**: Apache2, MySQL, PHP installation
- **Node.js**: Latest LTS with npm
- **Python**: Python3 with venv support
- **Angular**: Angular CLI with TypeScript
- **bat**: Enhanced cat replacement with syntax highlighting

### Shell Configuration
- **Zsh**: Modern shell with better features
- **Powerlevel10k**: Fast, customizable prompt with colors
- **Custom Aliases**: Git, Docker, and development shortcuts
- **bat Integration**: Syntax-highlighted file viewing

### Security & Integration
- **SSH Keys**: ed25519 key generation with ssh-agent
- **Git Setup**: User identity, SSH protocol, useful aliases
- **File Sync**: rsync with scp fallback
- **Watch Mode**: Automatic sync on file changes

### React Development
- **ESLint**: Airbnb style guide + React plugins
- **Component Generator**: Functional components with tests
- **Hook Templates**: Custom React hooks
- **Context Providers**: Complete context setup

### Update Management
- **Version Checking**: Compare against remote repository
- **Automatic Backup**: Creates backup before update
- **Fail-Safe Rollback**: Reverts on update failure
- **Backup Management**: List and restore previous versions

## Architecture

### Core Structure
```
bin/vm                           Main orchestration script (780+ lines)
core/
├── lib/                        Core libraries (500+ lines)
│   ├── colors.sh              Terminal colors and formatting
│   ├── error-handler.sh       Centralized error handling
│   ├── validation.sh          Input validation functions
│   └── common.sh              Utility functions
├── config/
│   └── defaults.sh            Default configuration
├── hypervisors/               Hypervisor drivers
│   ├── multipass-driver.sh   Multipass implementation
│   ├── virtualbox-driver.sh  VirtualBox implementation
│   ├── driver-registry.sh    Driver selection
│   └── hypervisor-interface.sh Driver interface
├── tools/                     Development tools (1500+ lines)
│   ├── tool-selector.sh      Tool selection menu
│   ├── lamp-installer.sh     LAMP stack
│   ├── nodejs-installer.sh   Node.js + npm
│   ├── python-installer.sh   Python3 + venv
│   ├── angular-installer.sh  Angular CLI
│   └── bat-installer.sh      bat tool
├── shells/                    Shell configuration (360+ lines)
│   ├── zsh-installer.sh      Zsh shell
│   ├── powerlevel10k-installer.sh  Prompt theme
│   └── shell-config.sh       Configuration generation
├── security/                  SSH and Git (460+ lines)
│   ├── ssh-keys.sh          SSH key management
│   ├── git-config.sh        Git configuration
│   ├── file-sync.sh         File synchronization
│   └── setup-git-ssh.sh     Complete setup
├── react/                     React development (560+ lines)
│   ├── eslint-setup.sh      ESLint configuration
│   └── component-generator.sh Component scaffolding
└── update/                    Update system (610+ lines)
    └── auto-updater.sh      Update management
```

### Key Libraries

#### colors.sh
```bash
print_section "Title"          # Major section
print_subsection "Subtitle"    # Minor section
print_ok "Success message"     # Green success
print_info "Info message"      # Blue info
print_error "Error message"    # Red error
print_warning "Warning"        # Yellow warning
```

#### validation.sh
```bash
validate_email "user@example.com"    # Email validation
validate_ip "192.168.1.1"           # IP address
validate_vm_name "my-vm"            # VM name
validate_url "https://example.com"  # URL validation
```

#### common.sh
```bash
is_root              # Check if running as root
has_sudo             # Check sudo availability
command_exists "git" # Check command exists
is_in_vm             # Detect if running in VM
get_os               # Get operating system
confirm "Continue?" # Yes/no prompt
```

## Command Reference

### VM Commands

#### Create VM
```bash
vm create my-vm                              # Default settings
vm create dev --cpus 4 --memory 8192         # Custom resources
vm create test --hypervisor virtualbox       # Specific hypervisor
vm create preview --dry-run                  # Preview only
```

#### Manage VMs
```bash
vm list                    # Show all VMs
vm start <name>           # Start VM
vm stop <name>            # Stop VM
vm delete <name>          # Delete (asks confirmation)
vm delete <name> --force  # Delete without asking
vm connect <name>         # SSH into VM
vm mount <name> <host> <vm>  # Mount directory
```

#### System Operations
```bash
vm diagnostic             # Show system information
vm cleanup                # Clean up resources
vm --help                 # Show all commands
vm --version              # Show version
```

### Setup Commands

#### Shell Configuration
```bash
vm setup-shell            # Install Zsh + Powerlevel10k + bat
```

Installs:
- Zsh shell
- Powerlevel10k prompt theme
- bat (syntax-highlighted cat)
- Custom aliases and environment variables

#### Git and SSH
```bash
vm setup-git-ssh          # Complete SSH/Git setup
```

Configures:
- SSH ed25519 key generation
- Git user identity
- SSH URL rewriting for Git
- Useful aliases (co, br, ci, st, etc.)

#### Development Tools
```bash
vm setup                  # Interactive menu
vm setup lamp             # Apache2 + MySQL + PHP
vm setup nodejs           # Node.js + npm
vm setup python           # Python3 + venv
vm setup angular          # Angular CLI
vm setup bat              # bat tool
vm setup lamp nodejs      # Multiple tools
```

#### React Development
```bash
vm setup-eslint           # Configure ESLint with Airbnb
vm generate-component <name>    # Create component
vm generate-hook <name>         # Create hook
vm generate-context <name>      # Create context
```

Examples:
```bash
vm setup-eslint .
vm generate-component Button
# Creates: Button/Button.jsx, .css, .test.jsx, index.js

vm generate-hook useAuth
# Creates: useAuth.js with hooks and tests

vm generate-context ThemeContext
# Creates: ThemeContext.jsx with Provider
```

### Update Commands

#### Check and Install Updates
```bash
vm update                 # Check and install updates
vm list-backups           # Show available backups
vm rollback <path>        # Restore previous version
vm update-log             # Show update history
```

## Development Phases

### Phase 1: Core Libraries ✅
**Files**: colors.sh, error-handler.sh, validation.sh, common.sh

Foundation libraries providing:
- Color output formatting
- Error handling and cleanup
- Input validation
- Utility functions

### Phase 2: VM Management ✅
**File**: bin/vm (780+ lines)

Main orchestration script with:
- Command routing
- Help documentation
- Option parsing
- Driver initialization

### Phase 3: Tool Installers ✅
**Files**: 6 scripts (1500+ lines)

Development tools with:
- Dependency management
- Consistent installation patterns
- Version verification
- Error recovery

### Phase 4: Shell Configuration ✅
**Files**: 4 scripts (360+ lines)

Shell setup featuring:
- Zsh installation
- Powerlevel10k integration
- Custom configuration
- bat integration

### Phase 5: Security & Sync ✅
**Files**: 4 scripts (460+ lines)

SSH/Git integration including:
- ed25519 key generation
- Git configuration
- File synchronization
- SSH setup

### Phase 6: React Development ✅
**Files**: 2 scripts (560+ lines)

React tooling with:
- ESLint configuration
- Component generation
- Hook templates
- Context providers

### Phase 7: Auto-Updater ✅
**File**: auto-updater.sh (610+ lines)

Update system providing:
- Version checking
- Backup creation
- Fail-safe rollback
- Update logging

## Best Practices

### VM Management
1. Name VMs descriptively: `dev-ubuntu`, `staging-lamp`
2. Create backups before major changes
3. Use consistent resource allocation
4. Mount code directories for easy editing

### Development Setup
1. Setup shell first for comfort
2. Configure Git/SSH early
3. Setup ESLint before React projects
4. Use generators for consistency

### Security
1. Generate SSH keys with meaningful comments
2. Add public key to Git hosting
3. Enable GPG signing for important commits
4. Keep backup history

### File Management
1. Monitor disk space
2. Clean old backups regularly
3. Version control everything
4. Test rollbacks in non-production

## Troubleshooting

### No Hypervisors Found
```bash
# Install Multipass (preferred)
snap install multipass

# Or install VirtualBox
apt-get install virtualbox

vm diagnostic  # Verify installation
```

### SSH Key Issues
```bash
# Check key permissions
ls -la ~/.ssh/
# private: 600, public: 644

# Regenerate keys if needed
vm setup-git-ssh

# Test connection
ssh -v github.com
```

### Git Configuration Problems
```bash
# Verify configuration
git config --global --list

# Reconfigure if needed
vm setup-git-ssh
```

### Rollback Needed
```bash
# List available backups
vm list-backups

# Restore previous version
vm rollback ~/.vm-scripts/backups/backup-VERSION

# Check update log
vm update-log
```

### Tool Installation Failures
```bash
# Check system
vm diagnostic

# Verify dependencies are installed
apt-get update
apt-get install build-essential

# Retry installation
vm setup lamp
```

## Code Quality

### Validation Standards
✅ Bash syntax correctness
✅ Proper error handling
✅ Input validation
✅ Security best practices
✅ Integration testing

See [VALIDATION.md](VALIDATION.md) for detailed report.

## Configuration

### Environment Variables
```bash
# Repository for updates
export REMOTE_REPO="https://github.com/YOUR_REPO/scripts-bash.git"

# VM defaults
export DEFAULT_CPUS="2"
export DEFAULT_MEMORY="4096"
export DEFAULT_DISK="15"
```

### Directory Structure
```
~/.vm-scripts/
├── updates/          # Temp files and repository
├── backups/          # Version backups
└── updates/update.log  # Update history
```

## Requirements

### System
- Linux (Ubuntu 18.04+, Debian 10+)
- Bash 4.0+
- 2GB RAM minimum
- 10GB disk space

### Tools
- git
- ssh
- rsync or scp
- npm (for React/Node.js)
- python3 (optional)

### Hypervisors
- Multipass (preferred)
- VirtualBox (alternative)

## Support & Documentation

- **Commands**: `vm --help`
- **System Info**: `vm diagnostic`
- **Validation**: See [VALIDATION.md](VALIDATION.md)
- **Original Repo**: See [README.md](README.md)

## Version

**Current Version**: 1.0.0
**Status**: Production Ready ✅
**Last Updated**: 2025-11-25

---

**Total Implementation**:
- 25+ scripts
- 5000+ lines of code
- 7 development phases
- Complete documentation
- Full validation report

All scripts follow bash best practices with proper error handling, input validation, and security measures.
