#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/35dryrun.txt");

$tm->run_tasks('parent');
ok(-f "t/35-dryrun-test", "startup tag-run worked");
ok(`cat t/35-dryrun-test` eq "123456789abcdefghijk", "content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/35-dryrun-test", "tag:cleanup command removed the output 1st run");


$tm->run_tasks({ dryrun => 1 }, 'parent');
ok(! -f "t/35-dryrun-test", "file is still missing");
