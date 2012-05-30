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

# the true test for proper order execution
$tm->run_tasks('parent');
ok(-f "t/10-parent-test", "output file for parent test exists");
ok(`cat t/10-parent-test` eq "1*2+3456789abcdefghijk",
   "parent test content is correct");
system("cp t/10-parent-test /tmp/abc");

$tm->run_tasks('fullclean');
ok(! -f "t/10-parent-test", "output file for parent test was removed");
