#!/bin/bash
# Intel GPU Monitoring - Monitored Host Installation Script
# Run this on the host with the Intel GPU

set -e

echo "=== Intel GPU Monitoring - Monitored Host Installation ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Check for required commands
echo "[1/8] Checking for required packages..."
MISSING_PACKAGES=""

if ! command -v intel_gpu_top &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES intel-gpu-tools"
fi

if ! command -v jq &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES jq"
fi

if ! command -v snmpd &> /dev/null; then
    MISSING_PACKAGES="$MISSING_PACKAGES snmpd"
fi

if [ -n "$MISSING_PACKAGES" ]; then
    echo "Missing packages:$MISSING_PACKAGES"
    read -p "Install missing packages? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apt update
        apt install -y $MISSING_PACKAGES
    else
        echo "ERROR: Required packages not installed. Exiting."
        exit 1
    fi
fi

echo "✓ All required packages present"

# Test intel_gpu_top
echo ""
echo "[2/8] Testing intel_gpu_top..."
if timeout 2 intel_gpu_top -J -s 1000 -o - >/dev/null 2>&1; then
    echo "✓ intel_gpu_top works"
else
    echo "WARNING: intel_gpu_top test failed. GPU may not be accessible."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install script
echo ""
echo "[3/8] Installing monitoring script..."
cp scripts/intel_gpu_monitor.sh /usr/local/bin/
chmod +x /usr/local/bin/intel_gpu_monitor.sh
chown root:root /usr/local/bin/intel_gpu_monitor.sh
echo "✓ Script installed to /usr/local/bin/intel_gpu_monitor.sh"

# Test script
echo ""
echo "[4/8] Testing monitoring script..."
if /usr/local/bin/intel_gpu_monitor.sh | jq . >/dev/null 2>&1; then
    echo "✓ Monitoring script works"
else
    echo "ERROR: Monitoring script test failed"
    exit 1
fi

# Install sudoers
echo ""
echo "[5/8] Installing sudoers configuration..."
cp sudoers.d/snmp-intel-gpu /etc/sudoers.d/
chmod 0440 /etc/sudoers.d/snmp-intel-gpu
chown root:root /etc/sudoers.d/snmp-intel-gpu

if visudo -c -f /etc/sudoers.d/snmp-intel-gpu >/dev/null 2>&1; then
    echo "✓ Sudoers file installed"
else
    echo "ERROR: Sudoers file syntax error"
    rm /etc/sudoers.d/snmp-intel-gpu
    exit 1
fi

# Configure SNMP
echo ""
echo "[6/8] Configuring SNMP..."
if grep -q "extend intel-gpu" /etc/snmp/snmpd.conf 2>/dev/null; then
    echo "! SNMP extend already configured"
else
    echo "extend intel-gpu /usr/local/bin/intel_gpu_monitor.sh" >> /etc/snmp/snmpd.conf
    echo "✓ SNMP extend added to snmpd.conf"
fi

# Restart SNMP
echo ""
echo "[7/8] Restarting SNMP daemon..."
systemctl restart snmpd
if systemctl is-active --quiet snmpd; then
    echo "✓ SNMP daemon restarted"
else
    echo "ERROR: SNMP daemon failed to start"
    systemctl status snmpd
    exit 1
fi

# Test SNMP
echo ""
echo "[8/8] Testing SNMP..."
echo "Please enter your SNMP community string (default: public):"
read -r COMMUNITY
COMMUNITY=${COMMUNITY:-public}

if snmpwalk -v2c -c "$COMMUNITY" localhost .1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117 2>/dev/null | grep -q "render_busy"; then
    echo "✓ SNMP test successful"
else
    echo "WARNING: SNMP test failed. Check your community string and firewall."
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. On your LibreNMS server, run the librenms-install.sh script"
echo "2. In LibreNMS web interface, add the 'intel-gpu' application to this device"
echo "3. Wait 10-15 minutes for graphs to populate"
echo ""
