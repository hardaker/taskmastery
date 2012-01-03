#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/30copies.txt");

$tm->run_tasks('test1');
ok(-f "t/30-copy-test", "startup tag-run worked");
ok(`cat t/30-copy-test` eq "p1-cfi1-cfi1-i1e-i2e-cfc1-cfc1-", "content is correct");

$tm->run_tasks('test2');
ok(-f "t/30-copy-test", "startup tag-run worked");
ok(`cat t/30-copy-test` eq "p1-cvi-foozies-cvi-barzies-ouch-{{FOOBAR}}-cvc-foozies-cvc-barzies-", "content in value replacement test is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/30-copy-test", "tag:cleanup command removed the output correctly");
