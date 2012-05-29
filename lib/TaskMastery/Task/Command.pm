package TaskMastery::Task::Command;

use TaskMastery::Task;
use Carp;
use strict;

our @ISA = qw(TaskMastery::Task);

our $VERSION = "0.1";

sub init {
    my ($self, $dryrun) = @_;
    $self->dryrun($dryrun, "Initializing: $self->{name}") if ($dryrun);
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
    return $self->run_commands_for('skipifnot', $dryrun);
}

sub run_commands_for {
    my ($self, $what, $dryrun) = @_;
    my $splitter = $self->get_config('break') || ";";
    my @commands = $self->split_config($what, ";");

    $self->set_directory();

    my $return = 0;
    foreach my $command (@commands) {
	if (defined($dryrun) && $dryrun ne '') {
	    $self->dryrun($dryrun, "running: $command");
	} else {
	    if ($self->get_option('verbose')) {
		$self->Verbose("* ($self->{'name'}) running: $command\n");
	    }
	    system($command);
	    $return = 1 if ($? != 0);
	}
    }
    return $return;
}

sub describe_keywords {
    return qw(skipifnot break init startup execute finished cleanup);
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
