
#!/bin/bash

# ==========================================
# Mac Health Check
# Version: 1.0.0
# Description: Lightweight macOS health check
# ==========================================

# Track health check results
PASS=0
WARN=0
FAIL=0

# Display a successful check and increment counter
pass() {
    echo "[PASS] $1"
    ((PASS++))
}

# Display a warning and increment counter
warn() {
    echo "[WARN] $1"
    ((WARN++))
}

# Display a failure and increment counter
fail() {
    echo "[FAIL] $1"
    ((FAIL++))
}

# Display section headings for readability
section() {
    echo
    echo "========== $1 =========="
}

# Check macOS version and hardware model
check_system() {
    section "SYSTEM INFORMATION"

    echo "macOS: $(sw_vers -productVersion)"
    echo "Model: $(sysctl -n hw.model)"
    echo "CPU:   $(sysctl -n hw.ncpu) cores"

    pass "System information collected"
}

# Check current disk usage on the main volume
check_disk() {
    section "DISK HEALTH"

    usage=$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')

    echo "Disk usage: ${usage}%"

    if (( usage >= 90 )); then
        fail "Disk space critically low"
    elif (( usage >= 80 )); then
        warn "Disk space running low"
    else
        pass "Disk space healthy"
    fi
}

# Check memory pressure using macOS VM statistics
check_memory() {
    section "MEMORY HEALTH"

    pressure=$(memory_pressure | awk -F ': ' '/System-wide memory free percentage/ {gsub(/%/,"",$2); print $2; exit}')

    if [[ -z "$pressure" ]]; then
        warn "Memory information unavailable"
    elif (( pressure < 10 )); then
        warn "Low free memory: ${pressure}%"
    else
        pass "Memory check completed: ${pressure}% free"
    fi
}

# Check whether the Mac can reach the internet
check_network() {
    section "NETWORK HEALTH"

    if ping -c 2 -W 2000 1.1.1.1 >/dev/null 2>&1; then
        pass "Internet connection available"
    else
        fail "Internet connection unavailable"
    fi
}

# Display battery condition on supported Mac models
check_battery() {
    section "BATTERY HEALTH"

    condition=$(system_profiler SPPowerDataType 2>/dev/null |
        awk -F ': ' '/Condition/ {print $2; exit}')

    if [[ "$condition" == "Normal" ]]; then
        pass "Battery condition normal"
    elif [[ -n "$condition" ]]; then
        warn "Battery condition: $condition"
    else
        warn "Battery information unavailable"
    fi
}

# Display how long the Mac has been running
check_uptime() {
    section "SYSTEM UPTIME"

    uptime
    pass "Uptime collected"
}

# Execute all health checks
main() {
    echo "================================"
    echo "       MAC HEALTH CHECK"
    echo "================================"
    echo "Date: $(date)"

    check_system
    check_disk
    check_memory
    check_network
    check_battery
    check_uptime

    section "FINAL SUMMARY"

    echo "PASS: $PASS"
    echo "WARN: $WARN"
    echo "FAIL: $FAIL"

    echo "================================"
}

main "$@"

