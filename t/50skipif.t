#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/50skipIfTest.txt");

$tm->run_tasks('parent');

ok(-f "t/50-created", "50-created is created");
ok(! -f "t/50-not-created", "50-not-created is not created");
ok(-f "t/50-created-conditionally", "50-created-conditionally is created");

ok(`cat t/50-created` eq "foo\n", "startup content is correct");
ok(`cat t/50-created-conditionally` eq "foo\n", "startup content is correct");

$tm->run_tasks('fullclean');
ok(! -f "t/50-parent-test", "output file for parent test was removed");
