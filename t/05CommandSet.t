#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/00config.txt");
ok($tm->config()->get('task','foo') eq 'bar', 'able to read config');

