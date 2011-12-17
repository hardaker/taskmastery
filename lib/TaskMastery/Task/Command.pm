package TaskMastery::Task::Command;

use TaskMastery::Task;
use Carp;
use strict;

our @ISA = qw(TaskMastery::Task);

our $VERSION = "0.1";

sub init {
    my ($self) = @_;
    $self->run_commands_for('init');
}

sub startup {
    my ($self) = @_;
    $self->run_commands_for('startup');
}

sub execute {
    my ($self) = @_;
    $self->run_commands_for('execute');
}

sub finished {
    my ($self) = @_;
    $self->run_commands_for('finished');
}

sub cleanup {
    my ($self) = @_;
    $self->run_commands_for('cleanup');
}

sub run_commands_for {
    my ($self, $what) = @_;
    my $config = $self->config();
    my $splitter = $config->get($self->name(), 'break') || ";";
    my @commands = $config->split($self->name(), $what, ";");
    foreach my $command (@commands) {
	system($command);
    }
}


1;

=pod

=head1 NAME

TaskMastery::Task::Commands - Executes Commands

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
