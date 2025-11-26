# Scripts Bash - VM Management & Development Automation

A comprehensive bash automation toolkit for VM management (Multipass, VirtualBox, Hyper-V, libvirt), LAMP stack configuration, and development environment setup.

---

## Quick Start

> **Two ways to use this project:**
> - **Automated VM creation**: Use `vm create` to automatically provision VMs with Multipass/VirtualBox
> - **Existing system/VM**: Install development tools directly on your current Ubuntu system or manually-created VM
>
> **Start with**: [Getting Started Guide](#getting-started)

---

## What This Project Does

A unified command-line toolkit for development environment automation:

1. **VM Management** - Create, manage, and configure VMs using Multipass, VirtualBox, Hyper-V, or libvirt
2. **LAMP Stack Installation** - Apache2 + PHP-FPM + MariaDB/MySQL + phpMyAdmin with environment-specific config
3. **Development Tools** - Node.js, Python, Shell improvements (zsh), Git/SSH setup, ESLint, and more
4. **Remote Development** - VSCode Remote-SSH for seamless remote editing from Windows/macOS/Linux

### Key Features

- ✅ **Multi-hypervisor support** (Multipass, VirtualBox, Hyper-V, libvirt - auto-detected)
- ✅ **Multi-environment configuration** (development/test/production)
- ✅ **Modular installation** (install only what you need: LAMP, Node, Python, etc.)
- ✅ **SSH & Git automation** (ed25519 keys, GitHub/GitLab setup)
- ✅ **VSCode Remote-SSH** (cross-platform: Windows, macOS, Linux)
- ✅ **Comprehensive documentation** (step-by-step guides with troubleshooting)

---

## Getting Started

### Option 1: Automated VM Creation (Recommended)

If you're on Ubuntu/Linux and want an automated VM:

```bash
# Clone the repository
git clone https://gitlab.com/kitadeve/scripts-bash.git
cd scripts-bash
chmod +x bin/vm core/**/*.sh

# Create and launch a VM automatically (Multipass/VirtualBox auto-detected)
./bin/vm create dev-vm --cpus 4 --memory 4096 --disk 20

# List VMs
./bin/vm list

# Connect to your VM
./bin/vm connect dev-vm
```

The `vm create` command automatically:
- Detects available hypervisor (Multipass, VirtualBox, Hyper-V, libvirt)
- Provisions Ubuntu VM with specified resources
- Configures networking and SSH access
- Sets up development environment

### Option 2: Existing System or Manual VM

If you already have an Ubuntu system or manually-created VM:

**Step 1: Clone and setup shell** (enables `vm` command globally)
```bash
git clone https://gitlab.com/kitadeve/scripts-bash.git
cd scripts-bash
chmod +x bin/vm core/**/*.sh

# Install shell tools and add to PATH
./bin/vm setup-shell
# Follow prompts, then reload shell
```

**After shell setup**, you can use `vm` globally:
```bash
vm --version      # Instead of ./bin/vm --version
vm help           # Show all available commands
```

**Step 2: Install what you need** (modular - pick and choose)

```bash
# Web development? Install LAMP stack
sudo vm setup lamp development    # Apache, MySQL, PHP, phpMyAdmin
                                  # Or: test, production

# JavaScript/Node.js development?
vm setup nodejs                   # Node.js + npm

# Python development?
vm setup python                   # Python 3 + venv

# Both? Install multiple tools
vm setup nodejs python            # Install several at once

# React development?
vm setup-eslint                   # ESLint with Airbnb style

# Git and SSH?
vm setup-git-ssh                  # Generate keys, configure Git
```

**All installations are optional and independent** - install only what your project needs.

### Common Workflows

**PHP/LAMP Development:**
```bash
vm setup-shell                    # Enable vm command globally
sudo vm setup lamp development    # Apache + MySQL + PHP
vm setup-git-ssh                  # Git and SSH configuration
```

**Full Stack (PHP + Node.js):**
```bash
vm setup-shell                    # Shell improvements first
sudo vm setup lamp development    # Backend (PHP)
vm setup nodejs eslint            # Frontend (Node.js + linting)
vm setup-git-ssh                  # Version control
```

**Node.js Only:**
```bash
vm setup-shell                    # Shell improvements
vm setup nodejs                   # Just Node.js, skip LAMP
vm setup-git-ssh                  # Version control
```

**Python Development:**
```bash
vm setup-shell                    # Shell improvements
vm setup python                   # Just Python, skip LAMP/Node
vm setup-git-ssh                  # Version control
```

### Remote Development with VSCode (Optional)

Connect VSCode from Windows/macOS/Linux to your VM:

**Guide**: [VSCODE-REMOTE-SSH.md](./docs/VSCODE-REMOTE-SSH.md)

Quick setup:
1. Run `vm setup-git-ssh` (creates SSH config)
2. Install VSCode Remote-SSH extension
3. Connect via Remote Explorer
4. Edit files remotely!

---

## Complete Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [README.md](./README.md) | Project overview and quick start | **START HERE** |
| [VM_SYSTEM_README.md](./docs/VM_SYSTEM_README.md) | Complete VM management guide | VM creation and management |
| [INSTALLATION-WORKFLOW.md](./docs/INSTALLATION-WORKFLOW.md) | Step-by-step manual VirtualBox setup | Manual VM setup walkthrough |
| [FIRST-STEPS.md](./docs/FIRST-STEPS.md) | Fresh Ubuntu setup guide | Manual VirtualBox VM initial setup |
| [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md) | LAMP stack detailed guide | LAMP installation reference |
| [VSCODE-REMOTE-SSH.md](./docs/VSCODE-REMOTE-SSH.md) | Remote development setup | VSCode remote connection |
| [VALIDATION.md](./docs/VALIDATION.md) | Code quality & testing report | Technical validation details |

---

## Project Structure

```
scripts-bash/
├── README.md                                 # This file
├── INSTALLATION-WORKFLOW.md                  # Master workflow guide
├── FIRST-STEPS.md                            # Phase 1: Initial setup
├── VSCODE-REMOTE-SSH.md                      # Phase 4: Remote development
├── VALIDATION.md                             # Code quality report
├── .version                                  # Version number
│
├── bin/
│   └── vm                                    # Main command (entry point)
│
├── core/
│   ├── lib/                                  # Core libraries
│   │   ├── colors.sh                         # Terminal colors & formatting
│   │   ├── error-handler.sh                  # Error handling & cleanup
│   │   ├── validation.sh                     # Input validation functions
│   │   └── common.sh                         # Common utilities
│   │
│   ├── tools/                                # Tool installers
│   │   ├── tool-selector.sh                  # Interactive tool menu
│   │   ├── lamp-installer.sh                 # LAMP stack installation
│   │   ├── nodejs-installer.sh               # Node.js installation
│   │   ├── python-installer.sh               # Python installation
│   │   ├── shell-config.sh                   # Shell configuration
│   │   ├── git-config.sh                     # Git/SSH setup
│   │   ├── ssh-keys.sh                       # SSH key generation
│   │   ├── eslint-setup.sh                   # ESLint for React
│   │   ├── component-generator.sh            # React component scaffolding
│   │   ├── bat-installer.sh                  # bat (cat replacement)
│   │   ├── powerlevel10k-installer.sh        # Zsh theme
│   │   ├── zsh-installer.sh                  # Zsh shell
│   │   ├── LAMP-INSTALLATION-GUIDE.md        # LAMP detailed guide
│   │   └── file-sync.sh                      # File synchronization
│   │
│   └── update/                               # Update management
│       └── auto-updater.sh                   # Version management & rollback
│
├── creation-vm-multipass-lamp/               # Legacy scripts (reference)
│   ├── create_webvm.sh
│   ├── connect_project.sh
│   ├── cleanup.sh
│   └── README.md
│
└── Config Projets MVC PHP/                   # Legacy scripts (reference)
    ├── creation-arborescence.sh
    ├── config.sh
    └── modele_tickets.sh
```

---

## Command Reference

### Main Command
```bash
vm [command] [options]
```

**Note**: After running `vm setup-shell`, the project is added to PATH, so you can use `vm` directly instead of `./bin/vm`.

### Available Commands

```bash
# Help & Info
vm help                          # Show all commands
vm --version                     # Show version
vm --help                        # Show detailed help

# VM Management (Multipass/VirtualBox/Hyper-V/libvirt)
vm create <name> [options]       # Create new VM
  --cpus <n>                     # Number of CPUs (default: 2)
  --memory <size>                # Memory in MB (default: 4096)
  --disk <size>                  # Disk in GB (default: 15)
  --hypervisor <type>            # Force specific hypervisor
vm list                          # List all VMs
vm start <name>                  # Start VM
vm stop <name>                   # Stop VM
vm delete <name>                 # Delete VM
vm connect <name>                # SSH into VM
vm mount <name> <local> <vm>     # Mount directory

# Setup Tools
vm setup                         # Interactive menu
vm setup lamp [env]              # LAMP stack (dev/test/prod)
vm setup nodejs                  # Node.js + npm
vm setup python                  # Python 3
vm setup-shell                   # zsh + powerlevel10k + bat
vm setup-git-ssh                 # SSH keys + Git config
vm setup-eslint                  # ESLint for React

# React Development
vm generate-component <name>     # Create React component
vm generate-hook <name>          # Create React hook
vm generate-context <name>       # Create React context

# System Info
vm diagnostic                    # System diagnostics
vm cleanup                       # Clean up resources

# Updates
vm update                        # Check and install updates
vm list-backups                  # Show available backups
vm rollback [backup]             # Restore from backup
```

### If Project Not in PATH Yet
```bash
# Before shell setup, use full path
./bin/vm setup-shell

# After shell setup, use simple syntax
vm [command]
```

---

## Database Credentials

LAMP installation creates hardcoded credentials for development convenience:

- **Username**: `superadmin`
- **Password**: `superpass`
- **phpMyAdmin URL**: http://localhost/phpmyadmin
- **Database Host**: `localhost:3306`

These can be changed manually after installation if needed.

---

## Environment-Specific Configuration

Each LAMP environment is configured differently:

| Aspect | Development | Test | Production |
|--------|-------------|------|------------|
| **PHP Errors** | Displayed on screen | Logged only | Logged only |
| **Memory Limit** | 512MB | 256MB | 128MB |
| **Execution Time** | 300s | 60s | 30s |
| **Query Logging** | Enabled | Disabled | Disabled |
| **Xdebug** | Enabled | Disabled | Disabled |
| **Opcache** | Disabled | Enabled | Enabled |
| **Security Headers** | Minimal | Minimal | Full |

---

## Troubleshooting

### No Hypervisor Found
```bash
# Install Multipass (recommended)
sudo snap install multipass

# Or VirtualBox
sudo apt-get install virtualbox

# Check what's available
vm diagnostic
```

### VM Creation Issues
```bash
# Check available hypervisors
vm diagnostic

# Try specific hypervisor
vm create my-vm --hypervisor multipass
vm create my-vm --hypervisor virtualbox
```

### LAMP Installation Issues
See [LAMP-INSTALLATION-GUIDE.md - Troubleshooting](./core/tools/LAMP-INSTALLATION-GUIDE.md#troubleshooting)

### VSCode Remote-SSH Connection Issues
See [VSCODE-REMOTE-SSH.md - Troubleshooting](./docs/VSCODE-REMOTE-SSH.md#troubleshooting)

### General Issues
```bash
# Run diagnostics
vm diagnostic

# Check service status (if LAMP installed)
sudo systemctl status apache2
sudo systemctl status mysql
sudo systemctl status php*-fpm

# View logs
tail -f /var/log/apache2/error.log
tail -f /var/log/mysql/error.log
tail -f /var/log/php_errors.log
```

---

## Development Workflow Examples

### Automated VM with LAMP
```bash
# Create VM automatically (Multipass/VirtualBox auto-detected)
vm create lamp-dev --cpus 4 --memory 4096 --disk 20

# Connect to your new VM
vm connect lamp-dev

# Inside the VM: Install shell and LAMP
./bin/vm setup-shell        # Setup shell + add to PATH
# Reload shell
sudo vm setup lamp development
vm setup-git-ssh

# From host: Connect with VSCode Remote-SSH
# → Already SSH-ready from vm create
```

### Existing System: PHP/LAMP Development
```bash
# On your existing Ubuntu system/VM
cd ~/projects/scripts-bash
./bin/vm setup-shell        # Install zsh, powerlevel10k, bat + add to PATH
# Reload shell to activate

# Install LAMP
sudo vm setup lamp development

# Setup Git/SSH
vm setup-git-ssh

# Connect with VSCode (if remote)
# → Install Remote-SSH extension
# → Connect to system
# → Edit files in /var/www/html
```

### Full Stack Development (PHP + Node.js)
```bash
# Setup shell first (enables vm command globally)
./bin/vm setup-shell
# Reload shell

# Install everything you need
sudo vm setup lamp development
vm setup nodejs eslint
vm setup-git-ssh

# Start developing!
```

### Node.js Only (No LAMP)
```bash
# Setup shell first
./bin/vm setup-shell
# Reload shell

# Just install Node.js, skip LAMP
vm setup nodejs
vm setup-git-ssh

# Run your app
cd ~/project
npm start

# Access via http://localhost:3000
```

---

## Performance Tips

### Development Environment
- Use SSD for VM storage
- Allocate 4GB+ RAM to VM
- Use bridged or NAT adapter for network
- Enable 3D acceleration in VirtualBox (if supported)

### Remote Development
- Use wired network (not WiFi)
- Enable compression in SSH config for slow networks
- Disable unnecessary VSCode extensions on remote

### Database
- Index frequently queried columns
- Use proper data types
- Monitor slow query logs (dev environment)

---

## Security Notes

### SSH Keys
- Private key (`id_ed25519`) should never be shared
- Key permissions should be 600 (`-rw-------`)
- Consider using a passphrase for extra security

### Credentials
- Development credentials (superadmin/superpass) are hardcoded for convenience
- Change credentials in production environments
- Use strong passwords for production

### Network
- SSH is only accessible from configured hosts
- Database only listens on localhost by default
- Use firewall rules in production

---

## Code Quality Standards

All scripts follow these standards:

- ✅ **ShellCheck** compliant (static analysis)
- ✅ **set -euo pipefail** (strict error handling)
- ✅ **Proper quoting** (variable protection)
- ✅ **Error handling** (comprehensive error checking)
- ✅ **Function documentation** (clear comments)
- ✅ **Consistent naming** (UPPERCASE constants, lowercase variables)

See [VALIDATION.md](./VALIDATION.md) for detailed code quality report.

---

## Contributing

Contributions are welcome! Please:

1. Test changes thoroughly
2. Follow bash best practices
3. Add documentation for new features
4. Submit clear pull requests with descriptions

---

## Legacy Scripts

This project has integrated and improved functionality from older scripts:
- `creation-vm-multipass-lamp/` - VM creation now integrated into `vm create` command
- `Config Projets MVC PHP/` - MVC project scaffolding

These legacy folders are kept for reference but the new unified `vm` command is recommended.

---

## License

These scripts are provided as examples for learning and automation purposes.
Free to use, modify, and redistribute.

---

## Support & Questions

### Getting Help
1. Check the **detailed guide** for your use case
2. Review the **troubleshooting section** in relevant guide
3. Run `vm diagnostic` for system info
4. Check **log files** for error details

### Documentation by Topic
- **VM Management**: [VM_SYSTEM_README.md](./docs/VM_SYSTEM_README.md)
- **Manual VirtualBox Setup**: [FIRST-STEPS.md](./docs/FIRST-STEPS.md)
- **LAMP Stack**: [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md)
- **Complete Workflow**: [INSTALLATION-WORKFLOW.md](./docs/INSTALLATION-WORKFLOW.md)
- **Remote Development**: [VSCODE-REMOTE-SSH.md](./docs/VSCODE-REMOTE-SSH.md)
- **Code Quality**: [VALIDATION.md](./docs/VALIDATION.md)

---

## Version Information

- **Current Version**: 1.0.0
- **Last Updated**: 2025-11-25
- **Bash Requirement**: 4.0+
- **Ubuntu Target**: 20.04 LTS / 22.04 LTS

---

**Ready to get started?** → [Read INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md)
