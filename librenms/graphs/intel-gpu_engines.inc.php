<?php

$name = 'intel-gpu';

$unit_text = 'Percent';
$colours = 'psychedelic';
$dostack = 0;
$printtotal = 0;
$addarea = 1;
$transparency = 15;

$rrd_filename = Rrd::name($device['hostname'], ['app', $name, $app->app_id]);

$rrd_list = [];
if (Rrd::checkRrdExists($rrd_filename)) {
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Render/3D',
        'ds' => 'render_busy',
    ];
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Video',
        'ds' => 'video_busy',
    ];
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Video Enhance',
        'ds' => 'videnhance_busy',
    ];
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Blitter',
        'ds' => 'blitter_busy',
    ];
} else {
    d_echo('RRD "' . $rrd_filename . '" not found');
}

require 'includes/html/graphs/generic_multi_line.inc.php';
