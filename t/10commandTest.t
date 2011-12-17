#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/10commandTest.txt");

$tm->run_tasks('createstuff');
ok(-f "t/10-startup-out", "startup command created");
ok(-f "t/10-startup-cleanup", "startup cleanup worked");
ok(`cat t/10-startup-cleanup` eq "foo\n", "cleanup content is correct");

$tm->run_tasks('destroystuff');
ok(! -f "t/10-startup-out", "startup command removed by cleanup");
ok(! -f "t/10-startup-cleanup", "startup cleanup removed by cleanup");
