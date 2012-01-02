#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('TaskMastery::Config'); }
require_ok('TaskMastery::Config');

my $config = new TaskMastery::Config();
ok(defined($config), "created a config object");
ok(ref($config) eq 'TaskMastery::Config', "created a refed config object");

$config->read_config("t/01include.txt");
ok(defined($config->{'config'}), "created internal config data");

# check that the values and extraction APIs work from 00 tests
ok($config->get('task', 'foo') eq 'bar', "basic test");
ok($config->get('task', 'override') eq 'it', "override test");

# check that our defaults were set before the include
ok($config->get('__DEFAULT__', 'bar') eq 'baz',
   "the core default value was in fact 'baz'");

# check that data after the include was accepted
ok($config->get('after', 'bee') eq 'foo',
   "the after bee value was foo");

# check the globbed imports
ok($config->get('multi1', 'foo') eq 'bar',
   "the multi1 foo value was bar, included by glob");

ok($config->get('multi2', 'foo2') eq 'bar2',
   "the multi2 foo2 value was bar2, included by glob");

# check that data after the include was accepted
ok($config->get('after2', 'honey') eq 'from bees',
   "the after2 honey value was from bees");

