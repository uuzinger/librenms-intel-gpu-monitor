#!/bin/bash
# Intel GPU monitoring script for LibreNMS
# Captures GPU stats via intel_gpu_top

# Use full paths for everything
CAPTURED=$(/usr/bin/sudo /usr/bin/timeout 2.5 /usr/bin/intel_gpu_top -J -s 1000 -o - 2>/dev/null || true)

# Take everything from beginning to first complete "}"
echo "$CAPTURED" | /usr/bin/sed -n '1,/^}$/p' | /usr/bin/tail -n +2 | /usr/bin/head -n -1 | \
  /usr/bin/jq -c '{
    "render_busy": (.engines."Render/3D".busy // 0),
    "blitter_busy": (.engines.Blitter.busy // 0),
    "video_busy": (.engines.Video.busy // 0),
    "video_enhance_busy": (.engines.VideoEnhance.busy // 0),
    "frequency_actual": (.frequency.actual // 0),
    "frequency_requested": (.frequency.requested // 0),
    "power_gpu": (.power.GPU // 0),
    "power_package": (.power.Package // 0),
    "rc6": (.rc6.value // 0),
    "interrupts": (.interrupts.count // 0)
  }' 2>/dev/null
