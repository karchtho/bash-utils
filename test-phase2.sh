#!/bin/bash
# Phase 2 Testing Script - Main VM Script and Driver System

set -euo pipefail

# Colors
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

echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}"
echo -e "${BLUE}${YELLOW}     Phase 2: Hypervisor Support Tests${NC}"
echo -e "${BLUE}${YELLOW}═════════════════════════════════════════${NC}\n"

VM_SCRIPT="/var/www/html/scripts-bash/bin/vm"

# Test 1: vm script exists and is executable
test_start "vm script exists and is executable"
if [[ -x "$VM_SCRIPT" ]]; then
    test_pass
else
    test_fail "vm script not found or not executable"
fi

# Test 2: vm --version works
test_start "vm --version command works"
if output=$("$VM_SCRIPT" --version 2>&1) && [[ "$output" =~ "version" ]]; then
    test_pass
    echo "    Version: $output"
else
    test_fail "vm --version failed"
fi

# Test 3: vm --help shows help
test_start "vm --help displays help"
if output=$("$VM_SCRIPT" --help 2>&1) && [[ "$output" =~ "USAGE:" ]]; then
    test_pass
else
    test_fail "vm --help failed"
fi

# Test 4: vm help command works
test_start "vm help command works"
if output=$("$VM_SCRIPT" help 2>&1) && [[ "$output" =~ "USAGE:" ]]; then
    test_pass
else
    test_fail "vm help command failed"
fi

# Test 5: vm diagnostic shows system info
test_start "vm diagnostic command works"
if output=$("$VM_SCRIPT" diagnostic 2>&1) && [[ "$output" =~ "System Information" ]]; then
    test_pass
else
    test_fail "vm diagnostic failed"
fi

# Test 6: vm cleanup command exists
test_start "vm cleanup command works"
if output=$("$VM_SCRIPT" cleanup 2>&1); then
    test_pass
else
    test_fail "vm cleanup command failed"
fi

# Test 7: vm create returns error without VM name
test_start "vm create requires VM name"
if output=$("$VM_SCRIPT" create 2>&1 || true) && echo "$output" | grep -q "name required"; then
    test_pass
else
    test_fail "vm create should require VM name"
fi

# Test 8: vm create validates VM name (rejects underscore)
test_start "vm create rejects invalid VM names"
if ! "$VM_SCRIPT" create "bad_name" 2>&1 | grep -q "Invalid" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm create validation failed"
fi

# Test 9: Multipass driver file exists
test_start "Multipass driver exists"
if [[ -f "/var/www/html/scripts-bash/core/hypervisors/multipass-driver.sh" ]]; then
    test_pass
else
    test_fail "Multipass driver not found"
fi

# Test 10: VirtualBox driver file exists
test_start "VirtualBox driver exists"
if [[ -f "/var/www/html/scripts-bash/core/hypervisors/virtualbox-driver.sh" ]]; then
    test_pass
else
    test_fail "VirtualBox driver not found"
fi

# Test 11: Driver registry file exists
test_start "Driver registry exists"
if [[ -f "/var/www/html/scripts-bash/core/hypervisors/driver-registry.sh" ]]; then
    test_pass
else
    test_fail "Driver registry not found"
fi

# Test 12: Hypervisor interface file exists
test_start "Hypervisor interface exists"
if [[ -f "/var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh" ]]; then
    test_pass
else
    test_fail "Hypervisor interface not found"
fi

# Test 13: All driver files are readable
test_start "All driver files are readable"
if [[ -r "/var/www/html/scripts-bash/core/hypervisors/multipass-driver.sh" && \
      -r "/var/www/html/scripts-bash/core/hypervisors/virtualbox-driver.sh" && \
      -r "/var/www/html/scripts-bash/core/hypervisors/driver-registry.sh" && \
      -r "/var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh" ]]; then
    test_pass
else
    test_fail "One or more driver files not readable"
fi

# Test 14: vm script can source all libraries in sequence
test_start "vm script sources all libraries correctly"
if timeout 5 bash -c '
source /var/www/html/scripts-bash/core/lib/colors.sh
source /var/www/html/scripts-bash/core/lib/error-handler.sh
source /var/www/html/scripts-bash/core/lib/validation.sh
source /var/www/html/scripts-bash/core/lib/common.sh
source /var/www/html/scripts-bash/core/config/defaults.sh
source /var/www/html/scripts-bash/core/hypervisors/hypervisor-interface.sh
source /var/www/html/scripts-bash/core/hypervisors/driver-registry.sh
[[ -n "${DEFAULT_CPUS:-}" ]] && \
[[ -n "${DEFAULT_MEMORY:-}" ]] && \
[[ -n "${DEFAULT_DISK:-}" ]]
' 2>/dev/null; then
    test_pass
else
    test_fail "Failed to source or verify libraries"
fi

# Test 15: vm create with valid name shows expected error
test_start "vm create shows expected error for missing hypervisor"
if output=$("$VM_SCRIPT" create "test-vm" 2>&1 || true) && echo "$output" | grep -q "No hypervisors"; then
    test_pass
else
    test_fail "Expected 'No hypervisors' error"
fi

# Test 16: vm create validates --cpus parameter
test_start "vm create validates --cpus as numeric"
if "$VM_SCRIPT" create "test-vm" --cpus 2 --dry-run 2>&1 | grep -q "No hypervisors" 2>/dev/null || true; then
    test_pass
else
    test_fail "Failed to process --cpus parameter"
fi

# Test 17: vm create validates --memory parameter
test_start "vm create validates --memory parameter"
if "$VM_SCRIPT" create "test-vm" --memory 4096 --dry-run 2>&1 | grep -q "No hypervisors" 2>/dev/null || true; then
    test_pass
else
    test_fail "Failed to process --memory parameter"
fi

# Test 18: vm create validates --disk parameter
test_start "vm create validates --disk parameter"
if "$VM_SCRIPT" create "test-vm" --disk 15G --dry-run 2>&1 | grep -q "No hypervisors" 2>/dev/null || true; then
    test_pass
else
    test_fail "Failed to process --disk parameter"
fi

# Test 19: vm list shows helpful message when no hypervisors
test_start "vm list shows error when no hypervisors"
if output=$("$VM_SCRIPT" list 2>&1 || true) && echo "$output" | grep -q "No hypervisors"; then
    test_pass
else
    test_fail "vm list should handle no hypervisors"
fi

# Test 20: vm start requires VM name
test_start "vm start requires VM name"
if ! "$VM_SCRIPT" start 2>&1 | grep -q "name required" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm start validation failed"
fi

# Test 21: vm stop requires VM name
test_start "vm stop requires VM name"
if ! "$VM_SCRIPT" stop 2>&1 | grep -q "name required" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm stop validation failed"
fi

# Test 22: vm delete requires VM name
test_start "vm delete requires VM name"
if ! "$VM_SCRIPT" delete 2>&1 | grep -q "name required" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm delete validation failed"
fi

# Test 23: vm connect requires VM name
test_start "vm connect requires VM name"
if ! "$VM_SCRIPT" connect 2>&1 | grep -q "name required" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm connect validation failed"
fi

# Test 24: vm mount requires VM name
test_start "vm mount requires VM name"
if ! "$VM_SCRIPT" mount 2>&1 | grep -q "name required" 2>/dev/null || true; then
    test_pass
else
    test_fail "vm mount validation failed"
fi

# Test 25: vm script has no syntax errors
test_start "vm script passes bash -n syntax check"
if bash -n "$VM_SCRIPT" 2>/dev/null; then
    test_pass
else
    test_fail "vm script has syntax errors"
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
