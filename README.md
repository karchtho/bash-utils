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

### Phase 1: Initial Ubuntu VirtualBox Setup
**Duration**: ~20 minutes
**Guide**: [FIRST-STEPS.md](./FIRST-STEPS.md)

- Create VirtualBox VM and install Ubuntu
- Configure AZERTY French keyboard (3 methods)
- Update system packages
- Clone this repository
- Verify scripts are executable

**Quick Command**:
```bash
sudo dpkg-reconfigure keyboard-configuration  # AZERTY setup
sudo apt-get update && sudo apt-get upgrade -y
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash && chmod +x bin/vm core/tools/*.sh core/lib/*.sh
./bin/vm --version  # Verify
```

### Phase 2: LAMP Stack Installation
**Duration**: ~10-15 minutes
**Guide**: [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md)

Install Apache2, MariaDB/MySQL, PHP-FPM, and phpMyAdmin with environment-specific configuration:

**Development** (recommended for local work):
```bash
sudo ./bin/vm setup lamp development
```
- Full error display, Xdebug support, query logging
- Access: http://localhost/phpmyadmin (superadmin/superpass)

**Test** (for CI/CD pipelines):
```bash
sudo ./bin/vm setup lamp test
```

**Production** (for live servers):
```bash
sudo ./bin/vm setup lamp production
```

### Phase 3: Optional Development Tools
**Duration**: ~3-5 minutes each
**Guide**: [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md) (Phase 3 section)

Install any combination of tools:

```bash
./bin/vm setup nodejs      # Node.js + npm
./bin/vm setup python      # Python 3
./bin/vm setup shell       # zsh + powerlevel10k
./bin/vm setup git-ssh     # SSH keys + Git config
./bin/vm setup eslint      # ESLint for React
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
./bin/vm [command] [options]
```

### Available Commands

```bash
# Help & Info
./bin/vm help                    # Show all commands
./bin/vm --version               # Show version
./bin/vm --help                  # Show detailed help

# Setup Tools
./bin/vm setup                   # Interactive menu
./bin/vm setup lamp              # LAMP stack
./bin/vm setup nodejs            # Node.js
./bin/vm setup python            # Python
./bin/vm setup shell             # zsh + powerlevel10k
./bin/vm setup git-ssh           # Git + SSH setup
./bin/vm setup eslint            # ESLint
./bin/vm setup [tool] [env]      # With environment (dev/test/prod)

# System Info
./bin/vm diagnose               # System diagnostics
./bin/vm version                # Show version

# Updates
./bin/vm update check           # Check for updates
./bin/vm update auto            # Auto-update with backup
./bin/vm list-backups           # Show available backups
./bin/vm rollback [backup]      # Restore from backup
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
# Phase 1: Setup Ubuntu
cd ~/projects/scripts-bash

# Phase 2: Install LAMP
sudo ./bin/vm setup lamp development

# Phase 3: Setup Git/SSH
./bin/vm setup git-ssh

# Phase 4: Connect with VSCode
# → Install Remote-SSH extension
# → Connect to ubuntu-vm
# → Edit files in /var/www/html
# → Run commands in terminal
```

### Full Stack Development (PHP + Node.js)
```bash
# Install LAMP for PHP
sudo ./bin/vm setup lamp development

# Install Node.js for JavaScript/React
./bin/vm setup nodejs

# Setup ESLint for code quality
./bin/vm setup eslint

# Configure development shell
./bin/vm setup shell

# Setup Git/SSH
./bin/vm setup git-ssh

# Connect with VSCode Remote-SSH
```

### Node.js Web Application
```bash
# Install Node.js
./bin/vm setup nodejs

# Install shell improvements
./bin/vm setup shell

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
