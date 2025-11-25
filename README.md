# Scripts Bash - VM Management & Development Automation

A comprehensive collection of bash scripts for automating VirtualBox VM setup, LAMP stack configuration, and development tool installation with complete documentation.

---

## Quick Start

> **New to this project?** Start here: [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md)

This guide walks you from a blank Ubuntu VirtualBox VM to a fully configured development environment in 4 phases (30-45 minutes total).

---

## What This Project Does

This is a modern replacement and enhancement of the older `creation-vm-multipass-lamp` scripts, reorganized into:

1. **Automated VM Setup** - Fresh Ubuntu configuration with keyboard layout, updates, and repo cloning
2. **LAMP Stack Installation** - Apache2 + PHP-FPM + MariaDB/MySQL + phpMyAdmin with environment-specific config
3. **Development Tools** - Node.js, Python, Shell improvements (zsh), Git/SSH setup, ESLint, and more
4. **Remote Development** - VSCode Remote-SSH for seamless remote editing from Windows/macOS/Linux

### Key Features

- ✅ **Multi-environment configuration** (development/test/production)
- ✅ **Non-interactive installation** (no prompts to answer)
- ✅ **AZERTY keyboard support** (French layout with 3 configuration methods)
- ✅ **SSH & Git automation** (ed25519 keys, GitHub/GitLab setup)
- ✅ **VSCode Remote-SSH** (cross-platform: Windows, macOS, Linux)
- ✅ **Comprehensive documentation** (step-by-step guides with troubleshooting)

---

## Installation Phases

Follow these 4 phases in order. Each has detailed documentation:

### Phase 1: Initial Ubuntu VirtualBox Setup + Shell Configuration
**Duration**: ~25 minutes
**Guide**: [FIRST-STEPS.md](./FIRST-STEPS.md)

Set up the VM and make the project immediately usable:

1. Create VirtualBox VM and install Ubuntu
2. Configure AZERTY French keyboard (3 methods)
3. Update system packages
4. Clone this repository
5. **Install shell tools** (zsh, powerlevel10k theme, bat)
6. **Add project to PATH** (so you can use `vm` instead of `./bin/vm`)

**Quick Command**:
```bash
sudo dpkg-reconfigure keyboard-configuration  # AZERTY setup
sudo apt-get update && sudo apt-get upgrade -y
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash && chmod +x bin/vm core/tools/*.sh core/lib/*.sh

# Install shell and add to PATH
./bin/vm setup shell
# Follow prompts to add project to PATH, then reload shell
```

**After Phase 1**, you can use:
```bash
vm --version      # Instead of ./bin/vm --version
vm setup lamp     # Instead of ./bin/vm setup lamp
vm help           # Show all available commands
```

### Phase 2: LAMP Stack Installation
**Duration**: ~10-15 minutes
**Guide**: [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md)

Install Apache2, MariaDB/MySQL, PHP-FPM, and phpMyAdmin with environment-specific configuration:

**Development** (recommended for local work):
```bash
sudo vm setup lamp development
```
- Full error display, Xdebug support, query logging
- Access: http://localhost/phpmyadmin (superadmin/superpass)

**Test** (for CI/CD pipelines):
```bash
sudo vm setup lamp test
```

**Production** (for live servers):
```bash
sudo vm setup lamp production
```

### Phase 3: Optional Development Tools
**Duration**: ~3-5 minutes each
**Guide**: [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md) (Phase 3 section)

Install any combination of additional tools:

```bash
vm setup nodejs      # Node.js + npm
vm setup python      # Python 3
vm setup git-ssh     # SSH keys + Git config
vm setup eslint      # ESLint for React
```

This phase also generates SSH keys and configures SSH for VSCode remote access.

### Phase 4: VSCode Remote-SSH (Optional)
**Duration**: ~5 minutes setup
**Guide**: [VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md)

Connect VSCode from your host machine to edit and debug code on the VM:

1. Install VSCode Remote - SSH extension
2. SSH config already created in Phase 3
3. Use Remote Explorer to connect
4. Start remote development!

Works on:
- Windows 10/11 (OpenSSH, Git Bash, or WSL2)
- macOS (built-in SSH)
- Linux (built-in SSH)

---

## Complete Documentation

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md) | Master orchestration guide | **START HERE** |
| [FIRST-STEPS.md](./FIRST-STEPS.md) | Fresh VM setup with keyboard config | Phase 1 detailed reference |
| [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md) | LAMP stack detailed guide | Phase 2 detailed reference |
| [VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md) | Remote development setup | Phase 4 reference |
| [VALIDATION.md](./VALIDATION.md) | Code quality & testing report | Technical validation details |

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

**Note**: After Phase 1 (`vm setup shell`), the project is added to PATH, so you can use `vm` directly instead of `./bin/vm`.

### Available Commands

```bash
# Help & Info
vm help                          # Show all commands
vm --version                     # Show version
vm --help                        # Show detailed help

# Setup Tools
vm setup                         # Interactive menu
vm setup lamp [env]              # LAMP stack (dev/test/prod)
vm setup nodejs                  # Node.js + npm
vm setup python                  # Python 3
vm setup shell                   # zsh + powerlevel10k + bat
vm setup git-ssh                 # SSH keys + Git config
vm setup eslint                  # ESLint for React

# System Info
vm diagnose                      # System diagnostics
vm version                       # Show version

# Updates
vm update check                  # Check for updates
vm update auto                   # Auto-update with backup
vm list-backups                  # Show available backups
vm rollback [backup]             # Restore from backup
```

### If Project Not in PATH Yet
```bash
# During Phase 1 before shell setup
./bin/vm setup shell

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

### AZERTY Keyboard Not Working
See [FIRST-STEPS.md - Troubleshooting](./FIRST-STEPS.md#troubleshooting)

### LAMP Installation Issues
See [LAMP-INSTALLATION-GUIDE.md - Troubleshooting](./core/tools/LAMP-INSTALLATION-GUIDE.md#troubleshooting)

### VSCode Remote-SSH Connection Issues
See [VSCODE-REMOTE-SSH.md - Troubleshooting](./VSCODE-REMOTE-SSH.md#troubleshooting)

### General Issues
```bash
# Run diagnostics
./bin/vm diagnose

# Check service status
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

### PHP/LAMP Development
```bash
# Phase 1: Initial setup (done first)
cd ~/projects/scripts-bash
./bin/vm setup shell        # Install zsh, powerlevel10k, bat + add to PATH
# Reload shell to activate

# Phase 2: Install LAMP
sudo vm setup lamp development

# Phase 3: Setup Git/SSH
vm setup git-ssh

# Phase 4: Connect with VSCode
# → Install Remote-SSH extension
# → Connect to ubuntu-vm
# → Edit files in /var/www/html
# → Run commands in terminal
```

### Full Stack Development (PHP + Node.js)
```bash
# Phase 1: Setup shell first (enables all following commands)
./bin/vm setup shell

# Phase 2: Install LAMP for PHP
sudo vm setup lamp development

# Phase 3: Install additional tools
vm setup nodejs             # Node.js + npm
vm setup eslint             # ESLint for React
vm setup git-ssh            # Git + SSH setup

# Phase 4: Connect with VSCode Remote-SSH
```

### Node.js Web Application
```bash
# Phase 1: Setup shell first
./bin/vm setup shell

# Phase 3: Install Node.js
vm setup nodejs

# Run app on VM
npm start

# Forward port via VSCode Remote-SSH
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

This project replaces the older scripts in:
- `creation-vm-multipass-lamp/` - Original VM setup scripts
- `Config Projets MVC PHP/` - MVC project scaffolding

These are kept for reference but the new modular approach is recommended.

---

## License

These scripts are provided as examples for learning and automation purposes.
Free to use, modify, and redistribute.

---

## Support & Questions

### Getting Help
1. Check the **detailed guide** for your phase
2. Review the **troubleshooting section** in relevant guide
3. Run `./bin/vm diagnose` for system info
4. Check **log files** for error details

### Documentation by Topic
- **Fresh VM Setup**: [FIRST-STEPS.md](./FIRST-STEPS.md)
- **LAMP Stack**: [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md)
- **Complete Workflow**: [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md)
- **Remote Development**: [VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md)
- **Code Quality**: [VALIDATION.md](./VALIDATION.md)

---

## Version Information

- **Current Version**: 1.0.0
- **Last Updated**: 2025-11-25
- **Bash Requirement**: 4.0+
- **Ubuntu Target**: 20.04 LTS / 22.04 LTS

---

**Ready to get started?** → [Read INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md)
