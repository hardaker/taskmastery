#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery'); }
require_ok('TaskMastery');

my $tm = new TaskMastery();
$tm->read_config("t/25multi.txt");

$tm->run_tasks('parenttask');
ok(-f "t/25-multi-test", "startup tag-run worked");
ok(`cat t/25-multi-test` eq "pi-t1-t2-c1-t1-c2-p-t1f-t1c-t1f-t1c-t2f-t2c-",
   "large content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/25-multi-test", "tag:cleanup command removed the output correctly");


$tm->run_tasks('reqtestgroup');
ok(`cat t/25-multi-test` eq "rtbe-rt1e-rt2e-rtbc-",
   "reqtestgroup content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/25-multi-test", "tag:cleanup command removed the output correctly");


$tm->run_tasks('reqtest1', 'reqtest2');
ok(`cat t/25-multi-test` eq "rtbe-rt1e-rt2e-rtbc-",
   "reqtest1/2 content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/25-multi-test", "tag:cleanup command removed the output correctly");



$tm->run_tasks('reqparent1', 'reqparent2');
ok(`cat t/25-multi-test` eq "rtbe-rt1e-rt2e-rtbc-",
   "reqtest1/2 content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/25-multi-test", "tag:cleanup command removed the output correctly");


$tm->run_tasks('reqparentgroup');
ok(`cat t/25-multi-test` eq "rtbe-rt1e-rt2e-rtbc-",
   "reqtest1/2 content is correct");

$tm->run_tasks('cleanup'); 
ok(! -f "t/25-multi-test", "tag:cleanup command removed the output correctly");
