# Installation Workflow: From Fresh VM to Full Setup

Complete step-by-step workflow for setting up a development environment from a fresh Ubuntu VirtualBox VM.

---

## Overview

This guide walks through the complete installation process in the correct order:

1. **Initial VM Setup** (FIRST-STEPS.md)
2. **LAMP Stack Installation** (LAMP-INSTALLATION-GUIDE.md)
3. **Optional: Additional Tools**

---

## Phase 1: Initial Ubuntu VirtualBox Setup

**Reference**: [FIRST-STEPS.md](./FIRST-STEPS.md)

### What This Phase Covers
- Creating a fresh VirtualBox VM with Ubuntu
- Configuring AZERTY French keyboard layout
- Updating system packages
- Cloning the scripts repository
- Setting up initial configuration

### Step-by-Step

```bash
# 1. After Ubuntu is installed, configure keyboard
sudo dpkg-reconfigure keyboard-configuration
# Choose: French → French (AZERTY)

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
chmod +x bin/vm
chmod +x core/tools/*.sh
chmod +x core/lib/*.sh

# 6. Verify installation
./bin/vm --version
# Should display: Version 1.0.0
```

### Expected Result
- AZERTY keyboard working correctly
- Repository cloned and scripts executable
- `./bin/vm --version` displays version
- `./bin/vm help` shows available commands

---

## Phase 2: LAMP Stack Installation

**Reference**: [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md)

### What This Phase Covers
- Apache2 installation with PHP-FPM support
- MariaDB/MySQL database server
- PHP 8.x with required extensions
- phpMyAdmin installation
- Environment-specific configuration

### Choose Your Environment

#### For Development (Most Common)
```bash
# Full error output, debugging support
sudo ./bin/vm setup lamp development
```

**Best for**:
- Local development
- Learning and experimentation
- Debugging applications

**Includes**:
- Error display on screen
- Query logging
- Xdebug support

#### For Testing
```bash
# Optimized for automated tests
sudo ./bin/vm setup lamp test
```

**Best for**:
- CI/CD pipelines
- Automated testing
- Staging environments

#### For Production
```bash
# Security and performance optimized
sudo ./bin/vm setup lamp production
```

**Best for**:
- Live servers
- Public applications
- Performance-critical systems

### Installation Steps

```bash
# 1. Run the installer (choose one)
sudo ./bin/vm setup lamp development

# 2. Wait for installation to complete (5-10 minutes)
# Installation will display progress and final summary

# 3. Note the displayed credentials
# Database User: superadmin
# Database Password: superpass
# phpMyAdmin URL: http://localhost/phpmyadmin

# 4. Create snapshot (optional but recommended)
# VirtualBox → Right-click VM → Snapshots → Take Snapshot
```

### Verify Installation

```bash
# Check services are running
sudo systemctl status apache2
sudo systemctl status mysql
sudo systemctl status php*-fpm

# Test PHP processing
curl http://localhost/test.php

# Test database connection
mysql -u superadmin -psuperpass -e "SELECT VERSION();"

# Access phpMyAdmin
# Open browser: http://localhost/phpmyadmin
# Login: superadmin / superpass
```

### Expected Result

```
LAMP Stack Installation Complete
─────────────────────────────────
Service Status:
  Apache2:  active (running)
  MySQL:    active (running)
  PHP-FPM:  active (running)

Database Access:
  User:     superadmin
  Password: superpass

phpMyAdmin:
  URL:      http://localhost/phpmyadmin
  User:     superadmin
  Password: superpass
```

---

## Phase 3: Optional Additional Tools

After LAMP is installed, you can add:

### Node.js
```bash
./bin/vm setup nodejs
```
Use for: JavaScript/TypeScript development, npm packages

### Python
```bash
./bin/vm setup python
```
Use for: Python development, data science, automation

### Shell Improvements
```bash
./bin/vm setup shell
```
Installs: zsh, powerlevel10k, better colors, aliases

### Git/SSH Configuration
```bash
./bin/vm setup git-ssh
```
Sets up: SSH keys, GitHub/GitLab integration, git aliases

### ESLint for React
```bash
./bin/vm setup eslint
```
Use for: React development, code quality

---

## Phase 4: VSCode Remote-SSH Configuration (Optional)

After completing phases 1-3, configure VSCode to connect and develop on your VM:

### Why Use Remote-SSH?
- **Edit code directly** on VM from your host VSCode
- **Run commands** on VM from integrated terminal
- **Debug applications** running on the VM
- **Access tools** installed on VM (PHP, Node, Python, etc.)
- **Works on Windows, macOS, and Linux**

### Quick Setup

1. **Install** Remote - SSH extension in VSCode
2. **SSH config** already created in Phase 3 (`vm setup git-ssh`)
3. **Connect** using VSCode Remote Explorer
4. **Start developing** immediately!

### Platform Notes

- **Windows 10/11**: Uses built-in OpenSSH (or Git Bash)
- **macOS**: SSH included, just needs configuration
- **Linux**: SSH included, just needs configuration

### Complete Reference

See **[VSCODE-REMOTE-SSH.md](./VSCODE-REMOTE-SSH.md)** for:
- Detailed setup for Windows, macOS, Linux
- Troubleshooting guide
- Advanced configuration options
- Performance optimization tips
- Port forwarding for web development

---

## Complete Timeline

### First Boot
```
1. Boot VM, configure keyboard (5 min)
2. Update system (5-10 min)
3. Clone repository (2 min)
```
**Total**: ~20 minutes

### LAMP Installation
```
1. Run installer (5-10 min)
2. Verify installation (2 min)
3. Create snapshot (1 min)
```
**Total**: ~10-15 minutes

### Optional Tools
```
Each tool takes 2-5 minutes depending on size
```

---

## Troubleshooting by Phase

### Phase 1: Initial Setup Issues

**Problem**: Can't type accented characters (AZERTY not working)
```bash
sudo dpkg-reconfigure keyboard-configuration
```

**Problem**: Repository clone fails
```bash
# Check internet
ping 8.8.8.8

# Check git is installed
git --version

# Try with ssh (if keys configured)
git clone ssh://git@github.com:USERNAME/scripts-bash.git
```

**Problem**: Scripts not executable
```bash
chmod +x bin/vm core/tools/*.sh core/lib/*.sh
./bin/vm --version  # Should work now
```

### Phase 2: LAMP Installation Issues

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

## Documentation Structure

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [FIRST-STEPS.md](./FIRST-STEPS.md) | Initial VM setup, keyboard, cloning | **First** - before doing anything |
| [LAMP-INSTALLATION-GUIDE.md](./core/tools/LAMP-INSTALLATION-GUIDE.md) | LAMP stack detailed guide | After first steps complete |
| [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md) | This document - complete workflow | Reference during setup |
| [README.md](./README.md) | Project overview | For general understanding |
| [VALIDATION.md](./VALIDATION.md) | Code quality report | For technical details |

---

## Quick Reference: Commands by Phase

### Phase 1: Initial Setup
```bash
sudo dpkg-reconfigure keyboard-configuration  # Keyboard
sudo apt-get update && sudo apt-get upgrade -y  # Update system
git clone https://github.com/YOUR_USERNAME/scripts-bash.git  # Clone repo
chmod +x scripts-bash/bin/vm  # Make executable
./scripts-bash/bin/vm --version  # Verify
```

### Phase 2: LAMP Installation
```bash
cd ~/projects/scripts-bash
sudo ./bin/vm setup lamp development  # Install LAMP
mysql -u superadmin -psuperpass -e "SELECT 1;"  # Verify
curl http://localhost/  # Check Apache
# Visit http://localhost/phpmyadmin in browser  # Check phpMyAdmin
```

### Phase 3: Optional Tools
```bash
./bin/vm setup nodejs    # Install Node.js
./bin/vm setup python    # Install Python
./bin/vm setup shell     # Install zsh + powerlevel10k
./bin/vm setup git-ssh   # Setup Git/SSH
```

---

## Summary

This workflow takes you from a blank Ubuntu VirtualBox VM to a fully functional development environment with:

- ✅ AZERTY keyboard support
- ✅ Git and development tools
- ✅ Apache2 web server with PHP-FPM
- ✅ MariaDB/MySQL database
- ✅ phpMyAdmin for database management
- ✅ Environment-specific configuration (dev/test/prod)
- ✅ Hardcoded superadmin/superpass credentials for development

**Total time**: ~30-45 minutes depending on internet speed and additional tools selected.

---

**Last Updated**: 2025-11-25
**Version**: 1.0.0
