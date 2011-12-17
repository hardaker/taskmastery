#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/00config.txt");
ok($tm->config()->get('task','foo') eq 'bar', 'able to read config');

# create an object for the first type of test
my $obj = $tm->create_task_object('task');
ok(ref($obj) eq 'TaskMastery::Task::Command',
   "created object is the right type");
ok($obj->name() eq 'task', "task is properly named");
