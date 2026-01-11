<?php

$name = 'intel-gpu';

$unit_text = 'MHz';
$colours = 'mixed';
$dostack = 0;
$printtotal = 0;
$addarea = 0;
$transparency = 15;

$rrd_filename = Rrd::name($device['hostname'], ['app', $name, $app->app_id]);

$rrd_list = [];
if (Rrd::checkRrdExists($rrd_filename)) {
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Actual',
        'ds' => 'freq_actual',
    ];
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Requested',
        'ds' => 'freq_requested',
    ];
} else {
    d_echo('RRD "' . $rrd_filename . '" not found');
}

require 'includes/html/graphs/generic_multi_line.inc.php';
