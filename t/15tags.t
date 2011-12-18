#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/15tags.txt");

$tm->run_tasks('tag:atag');
ok(-f "t/15-tag-test", "startup tag-run worked");
ok(`cat t/15-tag-test` eq "abc", "tag content is correct");

$tm->run_tasks('tag:cleanup');
ok(! -f "t/15-tag-test", "tag:cleanup command removed the output correctly");

$tm->run_tasks('parenttask');
ok(-f "t/15-tag-test", "startup parenttask tag-run worked");
ok(`cat t/15-tag-test` eq "acb", "parenttask tag content is correct");

$tm->run_tasks('tag:cleanup');
ok(! -f "t/15-tag-test", "tag:cleanup command removed the output correctly");
