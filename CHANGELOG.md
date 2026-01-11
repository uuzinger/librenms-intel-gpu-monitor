# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-10

### Added
- Initial release
- Support for Intel integrated GPUs (Gen 9+)
- Support for Intel Arc discrete GPUs
- Monitoring script using intel_gpu_top
- LibreNMS application module
- Three graph types:
  - GPU Engine Utilization (Render/3D, Video, Video Enhance, Blitter)
  - GPU Frequency (Actual vs Requested)
  - GPU Power Consumption (GPU and Package)
- SNMP extend integration
- Automated installation scripts for both monitored host and LibreNMS server
- Comprehensive documentation

### Metrics Tracked
- Render/3D engine utilization
- Video decode/encode engine utilization
- Video enhancement engine utilization
- Blitter/copy engine utilization
- GPU frequency (actual and requested)
- GPU power consumption
- Package power consumption
- RC6 residency (power saving state)
- GPU interrupt rate

### Supported Platforms
- Ubuntu 24.04 (tested)
- Debian-based Linux distributions
- LibreNMS 26.1.0+ (tested)

### Known Limitations
- Requires root access via sudo for intel_gpu_top
- Some integrated GPUs may not report GPU-specific power (will show 0)
- Graphs require 10-15 minutes to populate initial data
