#!/usr/bin/perl

use 5.026;
use utf8;
use strict;
use warnings;

use Device::Yeelight;

my ($room) = (
    Device::Yeelight::Light->new(location => 'yeelight://192.168.1.100:55443'),
);

$room->set_power('on', 'sudden', 0, 5);
$room->set_bright(90, 'sudden', 0);
