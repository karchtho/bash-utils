# First Steps: Fresh Ubuntu Setup

This guide covers **manual VirtualBox VM setup**. If you want automated VM creation, use `vm create` instead ([see VM_SYSTEM_README.md](./VM_SYSTEM_README.md)).

---

## Overview

**Two ways to get started:**

1. **Automated VM** (recommended): Use `vm create` to automatically provision a VM
2. **Manual VirtualBox** (this guide): Step-by-step manual VM setup

This guide is for **Option 2: Manual VirtualBox setup**.

---

## 1. Create VirtualBox VM (Manual)

### Create New Virtual Machine

1. Open VirtualBox
2. Click **New**
3. Configure:
   - **Name**: `Ubuntu-Dev` (or your choice)
   - **Type**: Linux
   - **Version**: Ubuntu (64-bit)
   - **Memory**: 4096 MB (4GB minimum recommended)
   - **Storage**: 50GB (dynamic allocation)
4. Click **Create**

### Install Ubuntu

1. Download Ubuntu Server ISO (Ubuntu 22.04 LTS recommended)
2. Mount ISO to VM
3. Start VM and follow Ubuntu installer:
   - Select language
   - Configure keyboard layout (choose AZERTY French if needed)
   - Network configuration
   - Storage configuration
   - User account creation
   - OpenSSH installation (recommended)
4. Reboot when complete

---

## 2. Configure AZERTY Keyboard

After Ubuntu is installed and running, configure your keyboard layout:

### Check Current Keyboard Layout

```bash
# View current layout
localectl status

# List available layouts
localectl list-x11-keymap-layouts
```

### Set AZERTY French Keyboard

#### Option A: Interactive Configuration (Recommended)

```bash
# Open keyboard configuration
sudo dpkg-reconfigure keyboard-configuration
```

Follow the prompts:
1. Select **French** as keyboard layout
2. Select **French (AZERTY)** as keyboard variant
3. Confirm settings
4. Reboot to apply

#### Option B: Command Line Configuration

```bash
# Set French AZERTY layout directly
sudo localectl set-x11-keymap fr pc105 azerty

# Set console keyboard layout
sudo loadkeys fr-latin9

# Make it permanent
echo "KEYMAP=fr-latin9" | sudo tee /etc/default/keyboard
```

#### Option C: Verify and Test

```bash
# Test keyboard mapping
grep -i keymap /etc/default/keyboard

# Check if working
# Try typing: @è(çà
# AZERTY result: à"({~
```

### Make Permanent (if not using dpkg-reconfigure)

Edit `/etc/default/keyboard`:

```bash
sudo nano /etc/default/keyboard
```

Ensure these lines are present:

```
XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT="azerty"
XKBOPTIONS=""
```

Save and reboot:

```bash
sudo reboot
```

---

## 3. Update System Packages

Before cloning the repository, update all system packages:

```bash
# Update package lists
sudo apt-get update

# Upgrade installed packages
sudo apt-get upgrade -y

# Install essential tools
sudo apt-get install -y \
  git \
  curl \
  wget \
  nano \
  vim \
  sudo \
  openssh-server \
  openssh-client

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean -y
```

---

## 4. Clone the Repository

### Option A: From GitHub (If you have internet)

```bash
# Create projects directory
mkdir -p ~/projects
cd ~/projects

# Clone the scripts repository
git clone https://github.com/YOUR_USERNAME/scripts-bash.git
cd scripts-bash

# List contents
ls -la
```

### Option B: From Local Network (If host has SSH)

```bash
# From VirtualBox VM, copy from host
# First, find your host IP (from host machine)
# Windows/Mac: ipconfig or ifconfig
# Linux: hostname -I

# Clone from host (using scp or git over SSH)
git clone ssh://your-username@HOST_IP:/path/to/scripts-bash
cd scripts-bash
```

### Option C: USB Drive Transfer

If internet access is limited:

1. On your host machine:
   ```bash
   cd ~/path/to/scripts-bash
   git bundle create scripts-bash.bundle --all
   ```

2. Copy `scripts-bash.bundle` to USB drive

3. On VM:
   ```bash
   mkdir -p ~/projects
   cd ~/projects
   git clone /path/to/usb/scripts-bash.bundle
   cd scripts-bash
   ```

---

## 5. Make Scripts Executable

After cloning, make all scripts executable:

```bash
# Navigate to repository
cd ~/projects/scripts-bash

# Make all scripts executable
chmod +x bin/vm
chmod +x core/tools/*.sh
chmod +x core/lib/*.sh
chmod +x core/update/*.sh

# Verify main script is executable
./bin/vm --version

# If successful, you should see version output
```

---

## 6. Verify Repository Contents

Check that all essential directories are present:

```bash
# Show directory structure
tree -L 2 -I 'node_modules'

# Or if tree not installed:
find . -maxdepth 2 -type d | sort
```

Should see:

```
.
├── bin/
│   └── vm                          # Main script
├── core/
│   ├── lib/                        # Core libraries
│   │   ├── colors.sh
│   │   ├── error-handler.sh
│   │   ├── validation.sh
│   │   └── common.sh
│   ├── tools/                      # Tool installers
│   │   ├── tool-selector.sh
│   │   ├── lamp-installer.sh
│   │   ├── nodejs-installer.sh
│   │   └── ...
│   └── update/                     # Update system
│       └── auto-updater.sh
├── README.md                       # Main documentation
└── .version                        # Version file
```

---

## 7. Test Basic Functionality

### Test Help Command

```bash
# Display help
./bin/vm --help

# Should show commands and options
```

### Check Available Tools

```bash
# Show available tools
./bin/vm setup

# Interactive menu should appear showing:
# Available tools: LAMP, Node.js, Python, Angular, bat, etc.
```

### Display Version

```bash
# Show current version
./bin/vm --version

# Should display: Version 1.0.0
```

---

## 8. Configure Git (Optional but Recommended)

Set up Git configuration for future commits:

```bash
# Configure user name
git config --global user.name "Your Name"

# Configure email
git config --global user.email "your.email@example.com"

# Verify configuration
git config --global -l
```

---

## 9. Initial VM Configuration

### Configure Locale (if not French)

```bash
# Check current locale
locale

# Set French locale (optional)
sudo update-locale LANG=fr_FR.UTF-8
sudo update-locale LC_TIME=fr_FR.UTF-8

# Reboot to apply
sudo reboot
```

### Configure Timezone

```bash
# Check current timezone
timedatectl

# List available timezones
timedatectl list-timezones | grep Paris

# Set Paris timezone
sudo timedatectl set-timezone Europe/Paris

# Verify
timedatectl
```

### Configure Hostname (Optional)

```bash
# Current hostname
hostname

# Set new hostname
sudo hostnamectl set-hostname ubuntu-dev

# Verify
hostnamectl
```

---

## 10. Network Configuration

### Verify Network Access

```bash
# Check IP address
ip addr show
# or
hostname -I

# Test internet connection
ping -c 3 8.8.8.8

# Test DNS
ping -c 3 github.com
```

### For VirtualBox NAT Adapter

If behind NAT and need to access VM from host:

1. In VirtualBox VM settings:
   - **Settings → Network → Adapter 1**
   - **Port Forwarding**
   - Add rules to forward host ports to VM

2. Example port mappings:
   ```
   Name      | Protocol | Host IP | Host Port | Guest IP | Guest Port
   HTTP      | TCP      | 0.0.0.0 | 8080      | 0.0.0.0  | 80
   HTTPS     | TCP      | 0.0.0.0 | 8443      | 0.0.0.0  | 443
   MySQL     | TCP      | 0.0.0.0 | 3306      | 0.0.0.0  | 3306
   SSH       | TCP      | 0.0.0.0 | 2222      | 0.0.0.0  | 22
   ```

---

## 11. Create Snapshot

Before installing development tools, create a VM snapshot:

```bash
# From host machine's VirtualBox
# Right-click VM → Snapshots → Take Snapshot
# Name: "Clean Ubuntu Install"
```

This allows rollback if something goes wrong during tool installation.

---

## 12. Next Steps

**Recommended: Install shell tools first** (makes `vm` command available globally):

```bash
./bin/vm setup shell
# Follow prompts to add to PATH
source ~/.zshrc  # or source ~/.bashrc
```

**After shell setup**, use `vm` instead of `./bin/vm`:

```bash
# Now you can use these commands (pick what you need):
sudo vm setup lamp development  # LAMP Stack
vm setup nodejs                 # Node.js
vm setup python                 # Python
vm setup git-ssh                # Git + SSH
vm setup eslint                 # ESLint for React
```

**Installation is modular** - install only what your project needs.

For more details, see:
- [INSTALLATION-WORKFLOW.md](./INSTALLATION-WORKFLOW.md) - Complete workflow
- [LAMP Installation Guide](../core/tools/LAMP-INSTALLATION-GUIDE.md) - LAMP details
- [Main README](../README.md) - Project overview

---

## Troubleshooting

### Can't type AZERTY characters

```bash
# Verify keyboard layout is active
setxkbmap -print

# Reset and reconfigure
sudo dpkg-reconfigure keyboard-configuration

# Test with:
# Type: é à ç
# Should display those accented characters
```

### Repository clone fails

```bash
# Check internet connection
ping -c 3 8.8.8.8

# Verify Git is installed
git --version

# Check SSH key (if using SSH clone)
ssh -T git@github.com
```

### Scripts not executing

```bash
# Check permissions
ls -la bin/vm

# Should show: -rwxr-xr-x (x means executable)

# If not executable:
chmod +x bin/vm
chmod +x core/tools/*.sh
chmod +x core/lib/*.sh
```

### Package installation too slow

```bash
# Change apt mirror to faster one
sudo nano /etc/apt/sources.list

# Replace ubuntu.com with local mirror
# Example for France: ubuntu.mirrors.ovh.net
```

---

## Keyboard Layout Quick Reference

### AZERTY Layout on QWERTY Keyboard

| Physical Key | AZERTY Output |
|--------------|---------------|
| A            | Q             |
| Z            | W             |
| W            | Z             |
| ; (colon)    | M             |
| M            | , (comma)     |
| , (comma)    | ? (question)  |

**Tip**: For passwords and code, remember the physical layout changes!

---

## Common Commands After Setup

**Before shell setup** (use `./bin/vm`):
```bash
./bin/vm --version              # Check version
./bin/vm help                   # View all commands
./bin/vm setup shell            # Install shell (do this first!)
```

**After shell setup** (use `vm`):
```bash
vm help                         # View all commands
vm diagnostic                   # System diagnostics
sudo vm setup lamp development  # Install LAMP
vm setup nodejs                 # Install Node.js
vm setup python                 # Install Python
vm setup git-ssh                # Setup Git + SSH
vm update                       # Check for updates
```

---

## System Information Commands

```bash
# Ubuntu version
lsb_release -a
# or
cat /etc/lsb-release-codename

# Kernel version
uname -a

# CPU info
nproc
lscpu | head -5

# Memory info
free -h

# Disk space
df -h /

# System uptime
uptime
```

---

**You are now ready to proceed with installing development tools!**

**Next Steps:**
1. [Install shell tools](./INSTALLATION-WORKFLOW.md#step-2-install-shell-tools-recommended-first) (recommended first)
2. [Install LAMP Stack](../core/tools/LAMP-INSTALLATION-GUIDE.md) (if doing web dev)
3. [Complete Workflow Guide](./INSTALLATION-WORKFLOW.md) (see all options)

---

**Last Updated**: 2025-11-25
**Version**: 1.0.0
