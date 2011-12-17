#!/usr/bin/perl

use Test::More qw(no_plan);
BEGIN { use_ok('SyncManager::Config'); }
require_ok('SyncManager::Config');

my $config = new SyncManager::Config();
ok(defined($config), "created a config object");
ok(ref($config) eq 'SyncManager::Config', "created a refed config object");

$config->read_config("t/00config.txt");
ok(defined($config->{'config'}), "created internal config data");

# check that the values and extraction APIs work
ok($config->get('task', 'foo') eq 'bar', "basic test");
ok($config->get('task', 'override') eq 'it', "override test");

my @array = $config->split('task', 'baz', ',');
ok($#array == 2, "split something into 3 pieces");
ok($array[0] eq 'it', 	    "1st object split is right");
ok($array[1] eq 'is', 	    "2nd object split is right");
ok($array[2] eq 'multiple', "3rd object split is right");

#### default value tests
ok($config->get('task', 'value') eq 'foo', "basic default value");
ok($config->get('__DEFAULT__', 'override') eq 'this',
   "the core default value was in fact 'this'");

@array = $config->split('task', 'listval', ',');
ok($#array == 1, "split default list into 2 pieces");
ok($array[0] eq 'listfoo1', "1st default object split is right");
ok($array[1] eq 'listfoo2', "2nd default object split is right");

