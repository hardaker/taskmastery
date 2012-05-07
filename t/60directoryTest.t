#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/60directoryTest.txt");

$tm->run_tasks('parent');

ok(-d "t/60-directoryTest",            "test directory was created");
ok(-f "t/60-directoryTest/myNewFile1", "test file 1 was created");
ok(-f "t/60-directoryTest/myNewFile2", "test file 2 was created");

$tm->run_tasks('fullclean');
ok(! -d "t/60-directoryTest",          "test directory was cleaned up");
