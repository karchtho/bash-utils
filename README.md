# Bash Utils - Experimental Scripts Collection

A collection of experimental bash automation scripts and advanced development tools. This repository contains work-in-progress and advanced implementations for VM management and development environment automation.

---

## 🚧 Status: Experimental / Archive

This repository contains **advanced/experimental** implementations of various bash automation tools. If you're looking for the **simple, working versions**, they've been moved to dedicated repositories:

### Production-Ready Tools (Recommended)

- **[vm-multipss-lamp](https://github.com/karchtho/vm-multipss-lamp)** - Simple VM creation with Multipass and LAMP stack (production-ready)
- **[php-mvc-generator](https://github.com/karchtho/php-mvc-generator)** - PHP MVC project scaffolding tool
- **[react-component-generator](https://github.com/karchtho/react-component-generator)** - React component scaffolding

---

## What's in This Repo

This repository contains an **advanced multi-hypervisor VM management system** with comprehensive development tool integration. It's more complex and feature-rich than the simple version, but may be overkill for most use cases.

### Features

- **Multi-hypervisor abstraction layer** - Unified interface for Multipass, VirtualBox, Hyper-V, and libvirt
- **Modular architecture** - Driver pattern for hypervisor support
- **Tool installation framework** - LAMP, Node.js, Python, Git/SSH automation
- **Auto-updater** - Version management with rollback support
- **Comprehensive error handling** - Advanced error handling and cleanup

### Project Structure

```
bash-utils/
├── bin/
│   └── vm                          # Main command entry point
│
├── core/
│   ├── lib/                        # Core libraries
│   │   ├── colors.sh               # Terminal formatting
│   │   ├── error-handler.sh        # Error handling & cleanup
│   │   ├── validation.sh           # Input validation
│   │   └── common.sh               # Common utilities
│   │
│   ├── hypervisors/                # Hypervisor drivers
│   │   ├── multipass-driver.sh     # Multipass support
│   │   ├── virtualbox-driver.sh    # VirtualBox support
│   │   ├── hyper-v-driver.sh       # Hyper-V support
│   │   └── libvirt-driver.sh       # libvirt support
│   │
│   ├── tools/                      # Tool installers
│   │   ├── lamp-installer.sh       # LAMP stack
│   │   ├── nodejs-installer.sh     # Node.js
│   │   ├── python-installer.sh     # Python
│   │   └── ...
│   │
│   ├── security/                   # Git/SSH configuration
│   ├── sync/                       # File synchronization
│   ├── update/                     # Auto-updater
│   └── config/                     # Default configurations
│
├── docs/                           # Documentation
└── test-phase*.sh                  # Testing scripts
```

---

## When to Use This vs. Simple Version

### Use the Simple Version ([vm-multipss-lamp](https://github.com/karchtho/vm-multipss-lamp)) if:
- ✅ You just need basic VM creation with Multipass
- ✅ You want LAMP stack setup
- ✅ You prefer simple, straightforward scripts
- ✅ You're getting started with VM automation

### Use This Advanced Version if:
- 🔬 You need multi-hypervisor support (VirtualBox, Hyper-V, libvirt)
- 🔬 You want a driver-based abstraction layer
- 🔬 You're experimenting with advanced automation
- 🔬 You want to contribute to or extend the framework

---

## Quick Start (Advanced Version)

```bash
# Clone the repository
git clone https://github.com/karchtho/bash-utils.git
cd bash-utils
chmod +x bin/vm core/**/*.sh

# Check available hypervisors
./bin/vm diagnostic

# Create VM (auto-detects best hypervisor)
./bin/vm create dev-vm --cpus 4 --memory 4096 --disk 20

# Or force specific hypervisor
./bin/vm create dev-vm --hypervisor virtualbox
./bin/vm create dev-vm --hypervisor multipass

# List VMs
./bin/vm list

# Connect to VM
./bin/vm connect dev-vm
```

---

## Available Commands

```bash
# VM Management
vm create <name> [options]       # Create new VM
  --cpus <n>                     # Number of CPUs (default: 2)
  --memory <size>                # Memory in MB (default: 4096)
  --disk <size>                  # Disk in GB (default: 15)
  --hypervisor <type>            # Force hypervisor (multipass/virtualbox/hyper-v/libvirt)
vm list                          # List all VMs
vm start <name>                  # Start VM
vm stop <name>                   # Stop VM
vm delete <name>                 # Delete VM
vm connect <name>                # SSH into VM
vm mount <name> <local> <vm>     # Mount directory

# Setup Tools
vm setup                         # Interactive tool menu
vm setup lamp [env]              # LAMP stack (development/test/production)
vm setup nodejs                  # Node.js + npm
vm setup python                  # Python 3
vm setup-git-ssh                 # SSH keys + Git config
vm setup-eslint                  # ESLint for React

# System
vm diagnostic                    # System diagnostics
vm update                        # Check for updates
vm rollback [backup]             # Restore from backup
vm --version                     # Show version
vm help                          # Show help
```

---

## Documentation

- [VM_SYSTEM_README.md](./docs/VM_SYSTEM_README.md) - Complete VM management guide
- [INSTALLATION-WORKFLOW.md](./docs/INSTALLATION-WORKFLOW.md) - Step-by-step setup
- [VALIDATION.md](./docs/VALIDATION.md) - Code quality report

---

## Development Status

This is an **experimental repository**. The code works but may be more complex than needed for most use cases. Consider using the simple version linked above unless you specifically need the advanced features.

### Known Limitations

- More complex than necessary for basic use cases
- Requires understanding of hypervisor abstractions
- May have edge cases with certain hypervisor combinations

---

## Contributing

This is primarily an experimental/learning repository. If you want to contribute:

1. Check if the simple version would be a better fit
2. Test thoroughly across different hypervisors
3. Follow bash best practices (ShellCheck compliant)
4. Add documentation for new features

---

## License

Free to use, modify, and redistribute for learning and automation purposes.

---

## Support

For questions or issues:
1. Check the [documentation](./docs/)
2. Run `vm diagnostic` for system info
3. Review relevant hypervisor documentation
4. Consider using the [simple version](https://github.com/karchtho/vm-multipss-lamp) if this is too complex

---

**Version**: 1.0.0
**Last Updated**: 2025-11-30
**Status**: Experimental
