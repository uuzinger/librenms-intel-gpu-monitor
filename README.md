# LibreNMS Intel GPU Monitoring

Monitor Intel integrated and Arc GPUs in LibreNMS with detailed metrics including engine utilization, frequency, and power consumption.

## Features

- **GPU Engine Utilization**: Track Render/3D, Video (transcoding), Video Enhance, and Blitter engines
- **GPU Frequency**: Monitor actual vs requested GPU frequency
- **Power Consumption**: Track GPU and package power usage
- **Hardware Transcoding**: Perfect for monitoring Jellyfin, Plex, or other media servers using Intel Quick Sync

## Supported Hardware

- Intel integrated GPUs (Gen 9+)
- Intel Arc discrete GPUs (A310, A380, A750, A770)
- Any GPU supported by `intel_gpu_top`

## Prerequisites

### On Monitored Host (GPU System)
- Ubuntu/Debian Linux (tested on Ubuntu 24.04)
- Intel GPU drivers installed
- `intel-gpu-tools` package installed
- `jq` package installed
- SNMP daemon (snmpd) installed and configured
- LibreNMS already monitoring the host via SNMP

### On LibreNMS Server
- LibreNMS 26.1.0+ (may work on older versions)
- Access to LibreNMS filesystem

## Installation

### Part 1: Monitored Host Setup

#### 1. Install Required Packages

```bash
sudo apt update
sudo apt install intel-gpu-tools jq snmpd -y
```

#### 2. Verify Intel GPU Tools Work

```bash
sudo intel_gpu_top
```

You should see GPU statistics. Press `q` to quit.

#### 3. Install Monitoring Script

```bash
sudo cp monitored-host/scripts/intel_gpu_monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/intel_gpu_monitor.sh
sudo chown root:root /usr/local/bin/intel_gpu_monitor.sh
```

#### 4. Test the Script

```bash
sudo /usr/local/bin/intel_gpu_monitor.sh
```

You should see JSON output with GPU metrics.

#### 5. Configure Sudo Permissions

```bash
sudo cp monitored-host/sudoers.d/snmp-intel-gpu /etc/sudoers.d/
sudo chmod 0440 /etc/sudoers.d/snmp-intel-gpu
sudo chown root:root /etc/sudoers.d/snmp-intel-gpu
```

Verify the sudoers file:
```bash
sudo visudo -c
```

Should output: `/etc/sudoers.d/snmp-intel-gpu: parsed OK`

#### 6. Configure SNMP

Add the extend line to your snmpd.conf:

```bash
echo "extend intel-gpu /usr/local/bin/intel_gpu_monitor.sh" | sudo tee -a /etc/snmp/snmpd.conf
```

Or manually add this line to `/etc/snmp/snmpd.conf`:
```
extend intel-gpu /usr/local/bin/intel_gpu_monitor.sh
```

#### 7. Restart SNMP

```bash
sudo systemctl restart snmpd
```

#### 8. Test SNMP Locally

Replace `YOUR_COMMUNITY` with your SNMP community string:

```bash
snmpwalk -v2c -c YOUR_COMMUNITY localhost .1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117
```

You should see the JSON data returned.

### Part 2: LibreNMS Server Setup

#### 1. Install Polling Module

```bash
sudo cp librenms/polling/intel-gpu.inc.php /opt/librenms/includes/polling/applications/
sudo chown librenms:librenms /opt/librenms/includes/polling/applications/intel-gpu.inc.php
```

#### 2. Install Graph Definitions

```bash
sudo cp librenms/graphs/*.inc.php /opt/librenms/includes/html/graphs/application/
sudo chown librenms:librenms /opt/librenms/includes/html/graphs/application/intel-gpu*.inc.php
```

#### 3. Install Application Page

```bash
sudo mkdir -p /opt/librenms/includes/html/pages/device/apps
sudo cp librenms/app-page/intel-gpu.inc.php /opt/librenms/includes/html/pages/device/apps/
sudo chown librenms:librenms /opt/librenms/includes/html/pages/device/apps/intel-gpu.inc.php
```

#### 4. Clear LibreNMS Cache

```bash
cd /opt/librenms
sudo -u librenms ./lnms config:cache
```

#### 5. Test SNMP from LibreNMS

Replace `YOUR_COMMUNITY` and `HOSTNAME` with appropriate values:

```bash
snmpwalk -v2c -c YOUR_COMMUNITY HOSTNAME .1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117
```

#### 6. Enable Application on Device

In LibreNMS web interface:
1. Navigate to your device
2. Click on "Applications" tab
3. Click "Add Application"
4. Type: `intel-gpu`
5. Click Save

#### 7. Force Initial Poll

```bash
cd /opt/librenms
sudo -u librenms ./lnms device:poll HOSTNAME --no-ansi
```

Replace `HOSTNAME` with your device hostname.

#### 8. Verify RRD File Creation

```bash
ls -lh /opt/librenms/rrd/HOSTNAME/app-intel-gpu*
```

You should see an RRD file created.

#### 9. View Graphs

In LibreNMS web interface:
1. Navigate to Devices → Your Device
2. Click "Applications" tab
3. Click "intel-gpu"
4. You should see three graphs:
   - GPU Engine Utilization
   - GPU Frequency  
   - GPU Power Consumption

**Note**: Graphs need 2-3 polling cycles (10-15 minutes) to populate with data.

## Metrics Collected

| Metric | Description | Unit |
|--------|-------------|------|
| render_busy | Render/3D engine utilization | Percent |
| video_busy | Video decode/encode engine utilization | Percent |
| video_enhance_busy | Video enhancement engine utilization | Percent |
| blitter_busy | Blitter/copy engine utilization | Percent |
| freq_actual | Current GPU frequency | MHz |
| freq_requested | Requested GPU frequency | MHz |
| power_gpu | GPU power consumption | Watts |
| power_package | Package power consumption | Watts |
| rc6 | RC6 residency (power saving state) | Percent |
| interrupts | GPU interrupt rate | irq/s |

## Monitoring Transcoding

When using hardware transcoding with Jellyfin, Plex, or similar:
- **Video engine** will show high utilization during transcoding
- **Video Enhance** may be used for scaling/deinterlacing
- **Power consumption** will increase during active transcoding

## Troubleshooting

### No data in graphs

1. **Check SNMP on monitored host:**
   ```bash
   snmpwalk -v2c -c YOUR_COMMUNITY localhost .1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117
   ```

2. **Check script execution:**
   ```bash
   sudo /usr/local/bin/intel_gpu_monitor.sh
   ```

3. **Check sudoers permissions:**
   ```bash
   sudo -u Debian-snmp /usr/local/bin/intel_gpu_monitor.sh
   ```
   (This may ask for password - that's expected from command line, but SNMP will work)

4. **Check LibreNMS logs:**
   ```bash
   tail -50 /opt/librenms/logs/librenms.log | grep -i intel
   ```

5. **Force a poll with verbose output:**
   ```bash
   cd /opt/librenms
   sudo -u librenms ./lnms device:poll HOSTNAME --no-ansi -vvv 2>&1 | grep -A 20 "intel-gpu"
   ```

### Script returns no data

- Verify Intel GPU drivers are installed
- Ensure `intel_gpu_top` works when run manually
- Check that `jq` is installed
- Verify script has execute permissions

### SNMP permission denied

- Check `/etc/sudoers.d/snmp-intel-gpu` is configured correctly
- Verify file permissions are 0440
- Test with: `sudo visudo -c`

### Graphs show but no data points

- Wait 10-15 minutes for multiple polling cycles
- Check RRD file exists: `ls -lh /opt/librenms/rrd/HOSTNAME/app-intel-gpu*`
- Verify file ownership is `librenms:librenms`

## Uninstallation

### On Monitored Host

```bash
# Remove SNMP extend line from /etc/snmp/snmpd.conf
sudo sed -i '/extend intel-gpu/d' /etc/snmp/snmpd.conf

# Remove script
sudo rm /usr/local/bin/intel_gpu_monitor.sh

# Remove sudoers file
sudo rm /etc/sudoers.d/snmp-intel-gpu

# Restart SNMP
sudo systemctl restart snmpd
```

### On LibreNMS Server

```bash
# Remove application from device in web interface first

# Remove files
sudo rm /opt/librenms/includes/polling/applications/intel-gpu.inc.php
sudo rm /opt/librenms/includes/html/graphs/application/intel-gpu*.inc.php
sudo rm /opt/librenms/includes/html/pages/device/apps/intel-gpu.inc.php

# Clear cache
cd /opt/librenms
sudo -u librenms ./lnms config:cache
```

## Contributing

Issues and pull requests welcome! This was developed for monitoring Jellyfin transcoding workloads but should work for any Intel GPU monitoring use case.

## License

MIT License - Feel free to use and modify as needed.

## Credits

Developed for monitoring Intel Arc GPUs in Jellyfin media servers. Based on LibreNMS application framework and uses `intel_gpu_top` from intel-gpu-tools.

## Version History

- **1.0.0** (2026-01-10) - Initial release
  - Support for Intel integrated and Arc GPUs
  - Three graph types: engines, frequency, power
  - Compatible with LibreNMS 26.1.0+
