<?php

$name = 'intel-gpu';

$unit_text = 'Watts';
$colours = 'mixed';
$dostack = 0;
$printtotal = 0;
$addarea = 1;
$transparency = 15;

$rrd_filename = Rrd::name($device['hostname'], ['app', $name, $app->app_id]);

$rrd_list = [];
if (Rrd::checkRrdExists($rrd_filename)) {
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'GPU Power',
        'ds' => 'power_gpu',
    ];
    $rrd_list[] = [
        'filename' => $rrd_filename,
        'descr' => 'Package Power',
        'ds' => 'power_package',
    ];
} else {
    d_echo('RRD "' . $rrd_filename . '" not found');
}

require 'includes/html/graphs/generic_multi_line.inc.php';
