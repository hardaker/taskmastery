package TaskMastery::Task::Command;

use TaskMastery::Task;
use Carp;
use strict;

our @ISA = qw(TaskMastery::Task);

our $VERSION = "0.1";

sub init {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('init', $dryrun);
}

sub startup {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('startup', $dryrun);
}

sub execute {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('execute', $dryrun);
}

sub finished {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('finished', $dryrun);
}

sub cleanup {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('cleanup', $dryrun);
}

sub check_skipif {
    my ($self, $dryrun) = @_;
    return $self->run_commands_for('skipif', $dryrun);
}

sub run_commands_for {
    my ($self, $what, $dryrun) = @_;
    my $splitter = $self->get_config('break') || ";";
    my @commands = $self->split_config($what, ";");

    my $return = 0;
    foreach my $command (@commands) {
	if (defined($dryrun) && $dryrun ne '') {
	    $self->dryrun($dryrun, "running: $command");
	} else {
	    system($command);
	    $return = 1 if ($? != 0);
	}
    }
    return $return;
}


1;

=pod

=head1 NAME

TaskMastery::Task::Command - Executes Commands

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
