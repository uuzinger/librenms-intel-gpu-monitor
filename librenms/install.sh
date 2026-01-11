#!/bin/bash
# Intel GPU Monitoring - LibreNMS Server Installation Script
# Run this on your LibreNMS server

set -e

echo "=== Intel GPU Monitoring - LibreNMS Server Installation ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root (use sudo)"
    exit 1
fi

# Check if LibreNMS directory exists
if [ ! -d "/opt/librenms" ]; then
    echo "ERROR: /opt/librenms directory not found. Is LibreNMS installed?"
    exit 1
fi

echo "[1/5] Installing polling module..."
cp polling/intel-gpu.inc.php /opt/librenms/includes/polling/applications/
chown librenms:librenms /opt/librenms/includes/polling/applications/intel-gpu.inc.php
echo "✓ Polling module installed"

echo ""
echo "[2/5] Installing graph definitions..."
cp graphs/*.inc.php /opt/librenms/includes/html/graphs/application/
chown librenms:librenms /opt/librenms/includes/html/graphs/application/intel-gpu*.inc.php
echo "✓ Graph definitions installed (3 files)"

echo ""
echo "[3/5] Installing application page..."
mkdir -p /opt/librenms/includes/html/pages/device/apps
cp app-page/intel-gpu.inc.php /opt/librenms/includes/html/pages/device/apps/
chown librenms:librenms /opt/librenms/includes/html/pages/device/apps/intel-gpu.inc.php
echo "✓ Application page installed"

echo ""
echo "[4/5] Clearing LibreNMS cache..."
cd /opt/librenms
sudo -u librenms ./lnms config:cache
echo "✓ Cache cleared"

echo ""
echo "[5/5] Testing SNMP connectivity..."
echo "Please enter the hostname of your monitored device:"
read -r HOSTNAME
echo "Please enter your SNMP community string (default: public):"
read -r COMMUNITY
COMMUNITY=${COMMUNITY:-public}

if snmpwalk -v2c -c "$COMMUNITY" "$HOSTNAME" .1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117 2>/dev/null | grep -q "render_busy"; then
    echo "✓ SNMP connectivity successful"
    
    echo ""
    echo "Would you like to trigger an initial poll now? (y/n)"
    read -r -n 1 REPLY
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo -u librenms ./lnms device:poll "$HOSTNAME" --no-ansi
        echo ""
        echo "Checking for RRD file..."
        sleep 2
        if ls /opt/librenms/rrd/"$HOSTNAME"/app-intel-gpu* >/dev/null 2>&1; then
            echo "✓ RRD file created successfully"
        else
            echo "! RRD file not created yet. This is normal - it will be created on next poll cycle."
        fi
    fi
else
    echo "WARNING: Could not reach monitored host via SNMP"
    echo "Please verify:"
    echo "  - Hostname is correct"
    echo "  - SNMP community string is correct"
    echo "  - Host is reachable from LibreNMS server"
    echo "  - Monitored host installation was completed"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. In LibreNMS web interface, go to your device"
echo "2. Click 'Applications' tab"
echo "3. Click 'Add Application'"
echo "4. Type 'intel-gpu' and save"
echo "5. Wait 10-15 minutes for graphs to populate"
echo ""
echo "To view graphs:"
echo "  Devices → $HOSTNAME → Applications → intel-gpu"
echo ""
