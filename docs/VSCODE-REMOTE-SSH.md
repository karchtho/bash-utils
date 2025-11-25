# VSCode Remote-SSH Configuration Guide

Complete guide for configuring VSCode Remote-SSH to connect to your Ubuntu VirtualBox VM from any operating system (Windows, macOS, Linux).

---

## Overview

VSCode Remote-SSH allows you to:
- Edit code directly on your VM from your host machine
- Run terminal commands on the VM
- Debug applications running on the VM
- Use all VSCode extensions on the remote machine

**This guide covers setup for Windows, macOS, and Linux hosts.**

---

## Prerequisites

Before starting, ensure you have:

### On Your Host Machine (Windows/Mac/Linux)
1. **VSCode installed**: [Download from code.visualstudio.com](https://code.visualstudio.com)
2. **VSCode Remote - SSH extension**: Install from Extensions marketplace
3. **SSH client**:
   - Windows 10/11: Built-in (or use Git Bash/WSL)
   - macOS/Linux: Built-in
4. **SSH key pair generated**: Created during LAMP installation via `vm setup git-ssh`

### On Your Ubuntu VM
1. **SSH server running**: `sudo systemctl status ssh`
2. **SSH configured in ~/.ssh/config**: Added during setup
3. **SSH key copied**: Private key available on host machine

---

## Step 1: Install VSCode Remote - SSH Extension

### On Your Host Machine

1. Open VSCode
2. Go to **Extensions** (Ctrl+Shift+X / Cmd+Shift+X)
3. Search for **"Remote - SSH"**
4. Click **Install** (by Microsoft)

After installation, you'll see a **Remote Explorer** icon on the left sidebar.

---

## Step 2: Verify SSH Configuration

### Check SSH Config File

Your SSH configuration should have been created when you ran `vm setup git-ssh`.

**On macOS/Linux:**
```bash
cat ~/.ssh/config
```

**On Windows (PowerShell):**
```powershell
Get-Content "$env:USERPROFILE\.ssh\config"
```

**Expected content:**
```
Host ubuntu-vm
    HostName 192.168.x.x
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes
```

### Update SSH Config if Needed

If your VM has a different IP or hostname, update the config:

**On macOS/Linux:**
```bash
nano ~/.ssh/config
# Edit the HostName to your VM's IP address
# Save (Ctrl+O, Enter, Ctrl+X)
```

**On Windows (PowerShell):**
```powershell
notepad "$env:USERPROFILE\.ssh\config"
# Edit and save
```

---

## Step 3: Verify SSH Keys

### Check SSH Key Permissions

**On macOS/Linux:**
```bash
ls -la ~/.ssh/
# Should see: -rw------- id_ed25519 (600 permissions)
#            -rw-r--r-- id_ed25519.pub (644 permissions)
```

**On Windows (PowerShell):**
```powershell
Get-Item "$env:USERPROFILE\.ssh\id_ed25519" | Select-Object FullName, Mode
# Should show -rw------- (Read/Write for owner only)
```

### If Permissions are Wrong (Windows only)

Windows sometimes has issues with SSH key permissions. Fix with:

```powershell
# Run as Administrator
$KeyPath = "$env:USERPROFILE\.ssh\id_ed25519"

# Remove inherited permissions
icacls $KeyPath /inheritance:r

# Grant read/write to current user only
icacls $KeyPath /grant:r "$env:USERNAME`:F"

# Verify permissions
icacls $KeyPath
```

---

## Step 4: Connect via Remote-SSH

### Method 1: Using Remote Explorer (Easiest)

1. Open VSCode
2. Click **Remote Explorer** icon (left sidebar)
3. Select **SSH Targets** from dropdown
4. Click **+** or **Add SSH Host**
5. Enter: `ubuntu-vm` (or your configured host name)
6. Select location to save config (usually `~/.ssh/config`)
7. Click **Connect** when the host appears

### Method 2: Command Palette

1. Open VSCode
2. Press **Ctrl+Shift+P** (Windows/Linux) or **Cmd+Shift+P** (macOS)
3. Type: **Remote-SSH: Connect to Host**
4. Select your VM from the list (e.g., `ubuntu-vm`)
5. Wait for connection

### Method 3: Direct Connection

1. Open VSCode
2. Click the **Remote Connection** button (bottom-left, looks like `><`)
3. Select **Connect to Host**
4. Choose your VM

---

## Step 5: First Connection

### Initial Connection Steps

1. VSCode will open a new window connecting to your VM
2. First time may ask about host verification - **select "Continue"**
3. May prompt for SSH key passphrase (if you set one)
4. Wait for VSCode to install remote server on VM (~30 seconds)

### After Connection

You'll see:
- Bottom-left shows: **SSH: ubuntu-vm**
- Explorer shows VM's filesystem
- Terminal opens to VM's shell

---

## Windows-Specific Setup

### Option A: Using OpenSSH (Windows 10/11 - Recommended)

Windows 10/11 includes OpenSSH. Enable it:

1. Open **Settings → Apps → Apps & features**
2. Click **Optional features**
3. Search for **"OpenSSH Client"**
4. If not installed:
   - Click **Add a feature**
   - Find **OpenSSH Client**
   - Click **Install**

### Option B: Using WSL2 (Windows Subsystem for Linux)

If OpenSSH doesn't work:

1. Enable WSL2: Open **PowerShell as Administrator**
   ```powershell
   wsl --install
   ```
2. Restart your computer
3. Open **Ubuntu** from Start menu (setup your Linux username/password)
4. Install OpenSSH client:
   ```bash
   sudo apt-get install openssh-client
   ```

### Option C: Using Git Bash

1. Download **Git for Windows** from git-scm.com
2. Install with SSH support
3. Use **Git Bash** terminal in VSCode

---

## macOS Setup

macOS includes SSH by default. Just:

1. Ensure SSH key exists: `ls ~/.ssh/id_ed25519`
2. If missing, create it: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`
3. Copy public key to VM (already done if using our setup scripts)

---

## Linux Setup

Linux includes SSH by default. Just:

1. Ensure SSH key exists: `ls ~/.ssh/id_ed25519`
2. If missing, create it: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`
3. Copy public key to VM (already done if using our setup scripts)

---

## Troubleshooting

### "Connection Refused" Error

**On VM - Check SSH is running:**
```bash
sudo systemctl status ssh
sudo systemctl start ssh
```

**On Host - Check SSH can reach VM:**
```bash
# Replace 192.168.x.x with your VM's IP
ssh -v ubuntu@192.168.x.x
```

### "Permission Denied (publickey)" Error

**On VM - Verify public key is authorized:**
```bash
cat ~/.ssh/authorized_keys
# Should contain your id_ed25519.pub content
```

**Copy key to VM if missing:**
```bash
# From host machine
ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@<VM_IP>
```

### "Host key verification failed" Error

**On Host - Clear known_hosts:**
```bash
# macOS/Linux
ssh-keygen -R ubuntu-vm

# Windows PowerShell
Remove-Item "$env:USERPROFILE\.ssh\known_hosts"
```

Then try connecting again.

### "Could not establish connection" in VSCode

1. **Verify SSH config:** Check host is correct in `~/.ssh/config`
2. **Check permissions:** SSH key should be 600 (`-rw-------`)
3. **Test SSH manually:** `ssh ubuntu-vm` from terminal
4. **Check firewall:** Ensure VM is accessible on network
5. **Restart SSH:** `sudo systemctl restart ssh` on VM

### Windows: "Invalid key format"

If using old RSA keys, regenerate:

```powershell
# Backup old key
Rename-Item "$env:USERPROFILE\.ssh\id_rsa" "id_rsa.bak"

# Generate new ed25519 key
ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\id_ed25519" -N ""

# Copy to VM
# Then manually add public key to VM's ~/.ssh/authorized_keys
```

---

## Advanced Configuration

### SSH Config Options (Optional Enhancements)

Edit `~/.ssh/config` to add options:

```
Host ubuntu-vm
    HostName 192.168.x.x
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    ForwardAgent yes

    # Auto-reconnect
    ServerAliveInterval 30
    ServerAliveCountMax 3

    # Performance
    Compression yes

    # Keep connection alive
    TCPKeepAlive yes
```

### Multiple VM Hosts

If you have multiple VMs:

```
Host ubuntu-dev
    HostName 192.168.1.100
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519

Host ubuntu-test
    HostName 192.168.1.101
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519

Host ubuntu-prod
    HostName 192.168.1.102
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
```

Then in VSCode, select which one to connect to.

### Port Forwarding

Forward ports from VM to host through VSCode:

1. Connect to VM via Remote-SSH
2. Open **Ports** tab in bottom panel
3. Click **Forward a Port**
4. Enter VM port (e.g., 3000 for Node.js)
5. Enter host port (e.g., 3000)
6. Access via `localhost:3000` on your host

### Remote Development Extensions

Install extensions on the remote server:

1. Connect via Remote-SSH
2. Go to **Extensions** in VSCode
3. Extensions you install are installed on VM
4. Recommended for remote development:
   - PHP Intelephense (PHP development)
   - Python (Python development)
   - ESLint (JavaScript/TypeScript)
   - Prettier (Code formatter)
   - REST Client (API testing)

---

## Workflow: Editing on Host, Running on VM

### Typical Development Flow

1. **Connect to VM** via Remote-SSH
2. **Open folder** on VM: `/var/www/html` (or your project)
3. **Edit files** using VSCode on host (files actually on VM)
4. **Run commands** in integrated terminal (executes on VM)
5. **Debug** directly on VM using VSCode debugger

### Example: PHP Development

```
VSCode (Windows)
    ↓
Remote-SSH tunnel
    ↓
Ubuntu VM
    ↓
Edit file in /var/www/html
    ↓
Run: php -S localhost:8000
    ↓
Access via http://localhost:8000
```

### Example: Node.js Development

```
VSCode (Windows)
    ↓
Remote-SSH tunnel
    ↓
Ubuntu VM
    ↓
Edit files in ~/projects/my-app
    ↓
Run: npm start
    ↓
Port forward 3000 → localhost:3000
    ↓
Access via http://localhost:3000
```

---

## Performance Tips

### For Slow Networks

1. Enable compression in SSH config:
   ```
   Compression yes
   ```

2. Increase network timeouts:
   ```
   ServerAliveInterval 60
   ServerAliveCountMax 5
   ```

3. Limit VSCode extensions to essential ones

4. Disable auto-sync when not needed

### For Better Performance

1. Use wired connection (not WiFi)
2. Ensure low latency to VM
3. Use SSD for VM storage
4. Allocate sufficient RAM to VM (4GB minimum)
5. Keep host and VM on same network

---

## Security Notes

### SSH Keys Safety

1. **Never share private key** (`id_ed25519`)
2. **Always keep backup** of private key
3. **Use passphrase** for extra security (add when creating key)
4. **Check key permissions** regularly (should be 600)

### Recommended Settings

```
# High security (better for public networks)
Host ubuntu-vm
    HostName 192.168.x.x
    User ubuntu
    IdentityFile ~/.ssh/id_ed25519
    PubkeyAuthentication yes
    PasswordAuthentication no
    PermitRootLogin no
    StrictHostKeyChecking accept-new
```

---

## Common Scenarios

### Scenario 1: Fresh Windows 11 Setup

```powershell
# 1. Install VSCode Remote SSH extension
# 2. SSH config already created: ~/.ssh/config
# 3. SSH key already created: ~/.ssh/id_ed25519
# 4. Open VSCode Remote Explorer
# 5. Click Connect to ubuntu-vm
# 6. Done!
```

### Scenario 2: macOS Development Setup

```bash
# 1. Install VSCode
# 2. Install Remote SSH extension
# 3. SSH setup already done
# 4. Open VSCode Remote Explorer
# 5. Connect to ubuntu-vm
# 6. Open remote folder: /var/www/html
# 7. Start editing!
```

### Scenario 3: Multiple Developers Same VM

If sharing a VM between developers:

1. Each developer generates their own SSH key
2. Admin adds all public keys to `~/.ssh/authorized_keys`
3. Each connects with their own host identity
4. VM maintains audit trail via SSH logs

---

## Verifying Connection

### Quick Verification Commands

After connecting via Remote-SSH:

```bash
# Open VSCode terminal (Ctrl+` or Ctrl+Shift+`)

# Check hostname
hostname

# Check current user
whoami

# Check working directory
pwd

# List files
ls -la

# Check if on VM
ip addr show
```

If these show VM info, you're successfully connected!

---

## Disconnecting

### Proper Disconnection

1. Click **Remote Connection** button (bottom-left)
2. Select **Close Remote Connection**
3. Or simply close the remote VSCode window

Your host VSCode will remain open.

---

## Quick Reference

| Task | Command / Action |
|------|------------------|
| Connect to VM | Remote Explorer → SSH Targets → ubuntu-vm |
| Check config | `cat ~/.ssh/config` |
| Test SSH | `ssh ubuntu-vm` |
| Copy SSH key to VM | `ssh-copy-id -i ~/.ssh/id_ed25519 ubuntu@<IP>` |
| Fix key permissions | `chmod 600 ~/.ssh/id_ed25519` |
| Clear known hosts | `ssh-keygen -R ubuntu-vm` |
| View remote files | Use Explorer in VSCode (when connected) |
| Run commands | Use integrated Terminal in VSCode |
| Forward port | Ports tab → Forward a Port |

---

## Additional Resources

- **VSCode Remote Development**: https://code.visualstudio.com/docs/remote/remote-overview
- **SSH Configuration**: https://linux.die.net/man/5/ssh_config
- **SSH Troubleshooting**: https://linux.die.net/man/1/ssh

---

**Last Updated**: 2025-11-25
**Version**: 1.0.0
