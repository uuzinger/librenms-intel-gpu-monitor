#!/bin/bash
# Intel GPU monitoring script for LibreNMS
# Captures GPU stats via intel_gpu_top

# Capture raw output
RAW=$(/usr/bin/sudo /usr/bin/timeout 3 /usr/bin/intel_gpu_top -J -s 1000 -o - 2>/dev/null || true)

# Extract the last complete JSON object and aggregate client engine usage
echo "$RAW" | /usr/bin/awk '
BEGIN { obj=""; capture=0; last_obj="" }
/^{$/ { capture=1; obj=$0"\n"; next }
capture==1 { obj=obj$0"\n" }
/^}$/ { 
    if (capture==1) {
        last_obj=obj
        capture=0
    }
}
END { print last_obj }
' | /usr/bin/jq -c '
# Sum up all client engine usage
(.clients // {} | to_entries | map(.value."engine-classes") | 
  if length > 0 then
    {
      render: (map(.["Render/3D"].busy // "0" | tonumber) | add),
      blitter: (map(.Blitter.busy // "0" | tonumber) | add),
      video: (map(.Video.busy // "0" | tonumber) | add),
      videnhance: (map(.VideoEnhance.busy // "0" | tonumber) | add)
    }
  else
    {render: 0, blitter: 0, video: 0, videnhance: 0}
  end
) as $client_usage |
{
  "render_busy": $client_usage.render,
  "blitter_busy": $client_usage.blitter,
  "video_busy": $client_usage.video,
  "video_enhance_busy": $client_usage.videnhance,
  "frequency_actual": (.frequency.actual // 0),
  "frequency_requested": (.frequency.requested // 0),
  "power_gpu": (.power.GPU // 0),
  "power_package": (.power.Package // 0),
  "rc6": (.rc6.value // 0),
  "interrupts": (.interrupts.count // 0)
}
' 2>/dev/null
