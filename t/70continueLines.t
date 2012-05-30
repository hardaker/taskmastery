#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/70continueLines.txt");

$tm->run_tasks('parent');

ok(-f "t/70-created1", "70-created1 is created");
ok(-f "t/70-created2", "70-created2 is created");

$tm->run_tasks('fullclean');
ok(! -f "t/70-created1", "output file for created1 test was removed");
ok(! -f "t/70-created2", "output file for created2 test was removed");
