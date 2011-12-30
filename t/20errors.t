#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/20errors.txt");

$tm->run_tasks('parenttask');
ok(-f "t/20-error-test", "startup tag-run worked");
ok(`cat t/20-error-test` eq "pa-a-1-b-2-pb-3-4-pc-", "tag content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/20-error-test", "tag:cleanup command removed the output correctly");
