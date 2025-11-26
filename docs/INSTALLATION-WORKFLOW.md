# Installation Workflow: Development Environment Setup

Complete guide for setting up a development environment - either on an automated VM or a manually-created VirtualBox VM.

---

## Overview

**Two approaches to use this project:**

1. **Automated VM Creation** - Use `vm create` to automatically provision a VM (Multipass/VirtualBox)
2. **Manual VirtualBox Setup** - Step-by-step manual VirtualBox VM configuration

Both approaches lead to the same modular tool installation - pick only what you need (LAMP, Node.js, Python, etc.).

---

## Approach 1: Automated VM Creation (Recommended)

If you're on Ubuntu/Linux and want an automated VM:

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash
chmod +x bin/vm core/**/*.sh

# Create VM automatically (auto-detects Multipass or VirtualBox)
./bin/vm create dev-vm --cpus 4 --memory 4096 --disk 20

# Connect to your VM
./bin/vm connect dev-vm

# Inside VM: Install shell and tools
./bin/vm setup shell          # Setup shell + add to PATH
# Reload shell
sudo vm setup lamp development  # Or any tools you need
vm setup git-ssh
```

**Duration**: ~15 minutes total

---

## Approach 2: Manual VirtualBox VM Setup

If you're manually creating a VirtualBox VM or using an existing Ubuntu system:

---

### Step 1: Initial Ubuntu VirtualBox Setup

**Reference**: [FIRST-STEPS.md](./FIRST-STEPS.md)

**What you'll do:**
- Create a fresh VirtualBox VM with Ubuntu (or use existing Ubuntu system)
- Configure keyboard layout if needed (AZERTY French keyboard)
- Update system packages
- Clone the scripts repository

**Steps:**

```bash
# 1. After Ubuntu is installed, configure keyboard (if needed)
sudo dpkg-reconfigure keyboard-configuration
# Choose: French → French (AZERTY), or your layout

# 2. Update system
sudo apt-get update && sudo apt-get upgrade -y

# 3. Install essential tools
sudo apt-get install -y git curl wget

# 4. Clone repository
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash

# 5. Make scripts executable
chmod +x bin/vm core/**/*.sh

# 6. Verify installation
./bin/vm --version
# Should display version number
```

**Duration**: ~15-20 minutes

---

### Step 2: Install Shell Tools (Recommended First)

**Makes `vm` command available globally** - do this before anything else.

```bash
# Install shell improvements + add to PATH
./bin/vm setup shell

# Follow prompts to add to PATH
# Then reload your shell
source ~/.zshrc  # or source ~/.bashrc
```

**After this step**, you can use `vm` instead of `./bin/vm` everywhere.

**Duration**: ~3-5 minutes

---

### Step 3: Install What You Need (Modular)

Now install only the tools your project requires. All installations are **optional and independent**.

#### Option A: LAMP Stack (Web Development)

**Reference**: [LAMP-INSTALLATION-GUIDE.md](../core/tools/LAMP-INSTALLATION-GUIDE.md)

Install Apache, MySQL, PHP, and phpMyAdmin:

```bash
# Development environment (recommended for learning/local dev)
sudo vm setup lamp development

# Test environment (for CI/CD)
sudo vm setup lamp test

# Production environment (for live servers)
sudo vm setup lamp production
```

**Includes**:
- Apache2 with PHP-FPM
- MariaDB/MySQL database
- PHP 8.x with extensions
- phpMyAdmin web interface
- Environment-specific configuration

**Duration**: ~10-15 minutes

#### Option B: Node.js (JavaScript/TypeScript Development)

```bash
vm setup nodejs
```

**Includes**: Node.js + npm

**Duration**: ~3-5 minutes

#### Option C: Python (Python Development)

```bash
vm setup python
```

**Includes**: Python 3 + venv support

**Duration**: ~2-3 minutes

#### Option D: Multiple Tools at Once

```bash
# Install several tools together
vm setup nodejs python
vm setup nodejs eslint
```

#### Option E: Git and SSH

```bash
vm setup git-ssh
```

**Includes**:
- SSH ed25519 key generation
- Git user configuration
- SSH config for remote development

**Duration**: ~2-3 minutes

---

### Common Installation Combinations

**PHP Web Development:**
```bash
./bin/vm setup shell          # First: enable vm command
source ~/.zshrc
sudo vm setup lamp development
vm setup git-ssh
```

**Full Stack (PHP + Node.js):**
```bash
./bin/vm setup shell
source ~/.zshrc
sudo vm setup lamp development
vm setup nodejs eslint git-ssh
```

**Node.js Only (No LAMP):**
```bash
./bin/vm setup shell
source ~/.zshrc
vm setup nodejs git-ssh
```

**Python Only:**
```bash
./bin/vm setup shell
source ~/.zshrc
vm setup python git-ssh
```

---

### Step 4: VSCode Remote-SSH (Optional)

If you want to edit code on your VM from Windows/macOS/Linux host:

**Reference**: [VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md)

**Quick setup:**
1. Run `vm setup git-ssh` (creates SSH config)
2. Install VSCode Remote-SSH extension on host
3. Connect via Remote Explorer
4. Edit files remotely!

**Works on**: Windows 10/11, macOS, Linux

---

## Verify Your Installation

### Check LAMP Services (if installed)

```bash
# Check services are running
sudo systemctl status apache2
sudo systemctl status mysql
sudo systemctl status php*-fpm

# Test database connection
mysql -u superadmin -psuperpass -e "SELECT VERSION();"

# Access phpMyAdmin: http://localhost/phpmyadmin
# Login: superadmin / superpass
```

### Check Node.js (if installed)

```bash
node --version
npm --version
```

### Check Python (if installed)

```bash
python3 --version
```

### Check Git/SSH (if installed)

```bash
git config --global --list
ls ~/.ssh/id_ed25519*
```

---

## Estimated Time

| Task | Duration |
|------|----------|
| **Automated VM Creation** | ~5-10 minutes |
| **Manual VM Setup** | ~15-20 minutes |
| **Shell Setup** | ~3-5 minutes |
| **LAMP Installation** | ~10-15 minutes |
| **Node.js Installation** | ~3-5 minutes |
| **Python Installation** | ~2-3 minutes |
| **Git/SSH Setup** | ~2-3 minutes |

**Total for full manual setup**: 30-45 minutes (depending on what you install)
**Total for automated VM + tools**: 20-30 minutes

---

## Troubleshooting

### Initial Setup Issues

**Problem**: Keyboard layout not working
```bash
sudo dpkg-reconfigure keyboard-configuration
```

**Problem**: Repository clone fails
```bash
# Check internet
ping 8.8.8.8

# Check git is installed
git --version
```

**Problem**: Scripts not executable
```bash
chmod +x bin/vm core/**/*.sh
./bin/vm --version  # Should work now
```

### LAMP Installation Issues

**Problem**: Apache won't start
```bash
# Check syntax
sudo apache2ctl configtest

# Check what's using port 80
sudo netstat -tlnp | grep :80
```

**Problem**: PHP-FPM socket issues
```bash
# Restart PHP-FPM
sudo systemctl restart php*-fpm

# Check socket
ls -la /run/php/php-fpm.sock
```

**Problem**: MySQL won't connect
```bash
# Check MySQL is running
sudo systemctl status mysql

# Check logs
sudo tail -50 /var/log/mysql/error.log

# Restart
sudo systemctl restart mysql
```

**Problem**: phpMyAdmin login fails
```bash
# Database user is always:
# Username: superadmin
# Password: superpass

# If still fails, check MySQL is running:
mysql -u superadmin -psuperpass -e "SELECT 1;"
```

---

## Useful Commands After Installation

### Check Environment Configuration
```bash
# See which environment is active
grep -r "LAMP_ENVIRONMENT" /etc/apache2/conf-available/

# Check PHP configuration
php -i | grep -A 5 "php.ini"

# View MySQL configuration
mysql -u superadmin -psuperpass -e "SHOW VARIABLES LIKE 'log%';"
```

### Manage Services
```bash
# Start/stop services
sudo systemctl start apache2      # Start Apache
sudo systemctl stop apache2       # Stop Apache
sudo systemctl restart apache2    # Restart Apache

# Check service logs
sudo journalctl -u apache2 -n 20  # Last 20 Apache entries
sudo journalctl -u mysql -n 20    # Last 20 MySQL entries
```

### Monitor Logs
```bash
# Real-time PHP errors
tail -f /var/log/php_errors.log

# Real-time Apache access
tail -f /var/log/apache2/access.log

# Real-time MySQL logs (dev only)
tail -f /var/log/mysql/query.log
```

### Create Development Database
```bash
mysql -u superadmin -psuperpass << EOF
CREATE DATABASE my_project_db;
CREATE USER 'my_project'@'localhost' IDENTIFIED BY 'my_password';
GRANT ALL PRIVILEGES ON my_project_db.* TO 'my_project'@'localhost';
FLUSH PRIVILEGES;
SHOW DATABASES;
EXIT;
EOF
```

---

## Documentation References

| Document | Purpose |
|----------|---------|
| [README.md](../README.md) | Project overview and quick start |
| [VM_SYSTEM_README.md](./VM_SYSTEM_README.md) | VM management with `vm create` |
| [FIRST-STEPS.md](./FIRST-STEPS.md) | Manual VirtualBox VM initial setup |
| [LAMP-INSTALLATION-GUIDE.md](../core/tools/LAMP-INSTALLATION-GUIDE.md) | LAMP stack detailed guide |
| [VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md) | Remote development setup |
| [VALIDATION.md](./VALIDATION.md) | Code quality report |

---

## Quick Reference Commands

### Automated VM Creation
```bash
vm create dev-vm --cpus 4 --memory 4096 --disk 20
vm connect dev-vm
```

### Manual Setup
```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash
chmod +x bin/vm core/**/*.sh

# Install shell (do this first!)
./bin/vm setup shell
source ~/.zshrc
```

### Install Tools (modular - pick what you need)
```bash
sudo vm setup lamp development    # Web dev
vm setup nodejs                   # JavaScript
vm setup python                   # Python
vm setup git-ssh                  # Git + SSH
vm setup eslint                   # React linting
```

### Verify
```bash
vm diagnostic                          # System info
sudo systemctl status apache2 mysql    # LAMP services
node --version                         # Node.js
python3 --version                      # Python
```

---

## Summary

This workflow provides **two paths** to a development environment:

**Automated**: `vm create` → automated VM with Ubuntu → install tools
**Manual**: VirtualBox manual setup → clone repo → install tools

**All tool installations are modular** - install only what you need:
- ✅ LAMP Stack (Apache, MySQL, PHP, phpMyAdmin)
- ✅ Node.js + npm
- ✅ Python 3 + venv
- ✅ Shell improvements (zsh, powerlevel10k)
- ✅ Git + SSH configuration
- ✅ ESLint for React

**Time**: 20-45 minutes depending on approach and tools selected.

---

**Last Updated**: 2025-11-25
**Version**: 1.0.0
