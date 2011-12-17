package TaskMastery::Task::Command;

use TaskMastery::Task;
use Carp;
use strict;

our @ISA = qw(TaskMastery::Task);

our $VERSION = "0.1";

my $DEFNAME = "__DEFAULT__";

1;

=pod

=head1 NAME

TaskMastery::Task::Commands - Executes Commands

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
