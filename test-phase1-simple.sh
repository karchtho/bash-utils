#!/bin/bash
# Simple Phase 1 Test - verify infrastructure files exist

echo "════════════════════════════════════════"
echo "     Phase 1: Infrastructure Check"
echo "════════════════════════════════════════"
echo ""

PASS=0
FAIL=0

check() {
    local name=$1
    local file=$2
    
    if [[ -f "$file" ]]; then
        echo "✓ $name"
        ((PASS++))
    else
        echo "✗ $name (missing: $file)"
        ((FAIL++))
    fi
}

# Check library files
echo "Core Libraries:"
check "Colors" "/var/www/html/scripts-bash/core/lib/colors.sh"
check "Error Handler" "/var/www/html/scripts-bash/core/lib/error-handler.sh"
check "Validation" "/var/www/html/scripts-bash/core/lib/validation.sh"
check "Common" "/var/www/html/scripts-bash/core/lib/common.sh"

echo ""
echo "Hypervisor System:"
check "Interface Definition" "/var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh"
check "Driver Registry" "/var/www/html/scripts-bash/core/hypervisors/driver-registry.sh"
check "Multipass Driver" "/var/www/html/scripts-bash/core/hypervisors/multipass-driver.sh"
check "VirtualBox Driver" "/var/www/html/scripts-bash/core/hypervisors/virtualbox-driver.sh"

echo ""
echo "Configuration:"
check "Defaults" "/var/www/html/scripts-bash/core/config/defaults.sh"

echo ""
echo "════════════════════════════════════════"
echo "Results: $PASS passed, $FAIL failed"
echo "════════════════════════════════════════"

if [[ $FAIL -eq 0 ]]; then
    echo "✓ Phase 1 Infrastructure Complete!"
    exit 0
else
    echo "✗ Some files are missing"
    exit 1
fi
