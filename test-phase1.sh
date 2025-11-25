#!/bin/bash
# Phase 1 Testing Script
# Tests core infrastructure and hypervisor detection

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

test_start() {
    TEST_COUNT=$((TEST_COUNT + 1))
    echo -ne "${BLUE}Test $TEST_COUNT: $1${NC}... "
}

test_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo -e "${GREEN}PASS${NC}"
}

test_fail() {
    local message=$1
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo -e "${RED}FAIL${NC}"
    echo "  Error: $message"
}

test_skip() {
    echo -e "${YELLOW}SKIP${NC}"
}

echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}"
echo -e "${BLUE}${YELLOW}     Phase 1: Core Infrastructure Tests${NC}"
echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}\n"

# Test 1: Check library files exist
test_start "Library files exist"
if [[ -f "/var/www/html/scripts-bash/core/lib/colors.sh" && \
      -f "/var/www/html/scripts-bash/core/lib/error-handler.sh" && \
      -f "/var/www/html/scripts-bash/core/lib/validation.sh" && \
      -f "/var/www/html/scripts-bash/core/lib/common.sh" ]]; then
    test_pass
else
    test_fail "One or more library files missing"
fi

# Test 2: Check hypervisor files exist
test_start "Hypervisor interface files exist"
if [[ -f "/var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh" && \
      -f "/var/www/html/scripts-bash/core/hypervisors/driver-registry.sh" && \
      -f "/var/www/html/scripts-bash/core/hypervisors/multipass-driver.sh" ]]; then
    test_pass
else
    test_fail "One or more hypervisor files missing"
fi

# Test 3: Check configuration defaults exist
test_start "Configuration defaults exist"
if [[ -f "/var/www/html/scripts-bash/core/config/defaults.sh" ]]; then
    test_pass
else
    test_fail "Configuration defaults file missing"
fi

# Test 4: Source colors library
test_start "Colors library sources correctly"
if source "/var/www/html/scripts-bash/core/lib/colors.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source colors.sh"
fi

# Test 5: Colors are defined
test_start "Color variables are defined"
if [[ -n "$RED" && -n "$GREEN" && -n "$BLUE" ]]; then
    test_pass
else
    test_fail "Color variables not defined"
fi

# Test 6: Source libraries in subshell
test_start "All core libraries source correctly"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh &&
source /var/www/html/scripts-bash/core/lib/error-handler.sh &&
source /var/www/html/scripts-bash/core/lib/validation.sh &&
source /var/www/html/scripts-bash/core/lib/common.sh
' 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source one or more libraries"
fi

# Test 7: Verify functions are properly exported
test_start "Common functions are available"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
declare -f command_exists >/dev/null && \
declare -f is_in_vm >/dev/null && \
declare -f detect_hypervisors >/dev/null
' 2>/dev/null; then
    test_pass
else
    test_fail "Functions not properly exported"
fi

# Test 8: Hypervisor interface (requires common.sh)
test_start "Hypervisor interface sources correctly"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
source /var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh
' 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source hypervisor-interface.sh"
fi

# Test 9: Driver registry (requires interface and common)
test_start "Driver registry sources correctly"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
source /var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh
source /var/www/html/scripts-bash/core/hypervisors/driver-registry.sh
' 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source driver-registry.sh"
fi

# Test 10: Detect hypervisors
test_start "Hypervisor detection works"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
detect_hypervisors
' 2>/dev/null > /tmp/hypervisors.txt; then
    available=$(cat /tmp/hypervisors.txt)
    if [[ -n "$available" ]]; then
        test_pass
        echo "    Available hypervisors: $available"
    else
        test_skip
        echo "    No hypervisors installed (this is okay for testing)"
    fi
else
    test_fail "Hypervisor detection failed"
fi

# Test 11: Check if Multipass is available (if installed)
test_start "Multipass availability detection"
if command -v multipass >/dev/null 2>&1; then
    if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
source /var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh
source /var/www/html/scripts-bash/core/hypervisors/multipass-driver.sh
driver_is_available
' 2>/dev/null; then
        test_pass
    else
        test_fail "Multipass not detected as available"
    fi
else
    test_skip
    echo "    Multipass not installed"
fi

# Test 12: Source configuration defaults
test_start "Configuration defaults sources correctly"
if source "/var/www/html/scripts-bash/core/config/defaults.sh" 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source defaults.sh"
fi

# Test 13: Default variables are set
test_start "Configuration defaults variables are set"
if [[ -n "${DEFAULT_HYPERVISOR:-}" && \
      -n "${DEFAULT_CPUS:-}" && \
      -n "${DEFAULT_MEMORY:-}" ]]; then
    test_pass
else
    test_fail "Configuration variables not set"
fi

# Test 14: Validation functions work
test_start "Validation functions work"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
validate_vm_name "test-vm" >/dev/null 2>&1
' 2>/dev/null; then
    test_pass
else
    test_fail "validate_vm_name failed on valid input"
fi

# Summary
echo ""
echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}"
echo -e "${BLUE}${YELLOW}              Test Summary${NC}"
echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}\n"
echo "Total tests:  $TEST_COUNT"
echo -e "Passed:       ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed:       ${RED}$FAIL_COUNT${NC}"
echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC} ✓"
    exit 0
else
    echo -e "${RED}$FAIL_COUNT test(s) failed.${NC} ✗"
    exit 1
fi
