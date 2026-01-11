<?php

use LibreNMS\RRD\RrdDefinition;

$name = 'intel-gpu';

// Get the data from SNMP extend using numeric OID
$intel_gpu_data = snmp_get($device, '.1.3.6.1.4.1.8072.1.3.2.4.1.2.9.105.110.116.101.108.45.103.112.117.1', '-Oqv');

if (!empty($intel_gpu_data)) {
    // Remove surrounding quotes and unescape the JSON
    $intel_gpu_data = trim($intel_gpu_data, '"');
    $intel_gpu_data = stripslashes($intel_gpu_data);
    
    // Parse JSON
    $gpu_stats = json_decode($intel_gpu_data, true);
    
    if (json_last_error() === JSON_ERROR_NONE && is_array($gpu_stats)) {
        $rrd_name = ['app', $name, $app->app_id];
        $rrd_def = RrdDefinition::make()
            ->addDataset('render_busy', 'GAUGE', 0, 100)
            ->addDataset('blitter_busy', 'GAUGE', 0, 100)
            ->addDataset('video_busy', 'GAUGE', 0, 100)
            ->addDataset('videnhance_busy', 'GAUGE', 0, 100)
            ->addDataset('freq_actual', 'GAUGE', 0, 3000)
            ->addDataset('freq_requested', 'GAUGE', 0, 3000)
            ->addDataset('power_gpu', 'GAUGE', 0, 500)
            ->addDataset('power_package', 'GAUGE', 0, 500)
            ->addDataset('rc6', 'GAUGE', 0, 100)
            ->addDataset('interrupts', 'GAUGE', 0);

        $fields = [
            'render_busy' => $gpu_stats['render_busy'] ?? 0,
            'blitter_busy' => $gpu_stats['blitter_busy'] ?? 0,
            'video_busy' => $gpu_stats['video_busy'] ?? 0,
            'videnhance_busy' => $gpu_stats['video_enhance_busy'] ?? 0,
            'freq_actual' => $gpu_stats['frequency_actual'] ?? 0,
            'freq_requested' => $gpu_stats['frequency_requested'] ?? 0,
            'power_gpu' => $gpu_stats['power_gpu'] ?? 0,
            'power_package' => $gpu_stats['power_package'] ?? 0,
            'rc6' => $gpu_stats['rc6'] ?? 0,
            'interrupts' => $gpu_stats['interrupts'] ?? 0,
        ];

        $tags = ['name' => $name, 'app_id' => $app->app_id, 'rrd_def' => $rrd_def, 'rrd_name' => $rrd_name];
        app('Datastore')->put($device, 'app', $tags, $fields);
        
        update_application($app, $intel_gpu_data, $fields);
    }
}

unset($intel_gpu_data, $gpu_stats, $rrd_name, $rrd_def, $fields, $tags);
