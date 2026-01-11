# Quick Start Guide

## TL;DR Installation

### On Monitored Host (GPU System)
```bash
tar -xzf librenms-intel-gpu-monitoring-1.0.0.tar.gz
cd librenms-intel-gpu-monitoring/monitored-host
sudo ./install.sh
```

### On LibreNMS Server
```bash
tar -xzf librenms-intel-gpu-monitoring-1.0.0.tar.gz
cd librenms-intel-gpu-monitoring/librenms
sudo ./install.sh
```

### In LibreNMS Web Interface
1. Go to your device
2. Applications tab
3. Add Application → `intel-gpu`
4. Wait 10-15 minutes for graphs

## What Gets Monitored

- **GPU Engines**: Render/3D, Video (transcoding), Video Enhance, Blitter
- **Frequency**: Actual vs Requested GPU frequency  
- **Power**: GPU and Package power consumption

## Perfect For

- Monitoring Jellyfin/Plex hardware transcoding
- Tracking Intel Quick Sync usage
- Intel Arc GPU utilization
- Integrated GPU monitoring

## Requirements

- Intel GPU (integrated or Arc)
- Ubuntu/Debian Linux
- LibreNMS already monitoring the host
- Root/sudo access on both systems

## Support

See full README.md for detailed installation, troubleshooting, and configuration options.
