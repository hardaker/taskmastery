package TaskMastery::Task;

use TaskMastery;
use Carp;
use strict;

our $VERSION = "0.1";
our @ISA = qw(TaskMastery);

sub start {
    my ($self) = @_;

    my $config = $self->config();

    # find 'before' childen and execute them entirely
    $self->{'beforeobjs'} =
	$self->collect_tasks_by_name($config->split($self->name(), 'before'));
    foreach my $obj (@{$self->{'beforeobjs'}}) {
	$obj->start();
	$obj->finish();
    }

    # find 'require' childen and execute just their start routines
    $self->{'requireobjs'} =
	$self->collect_tasks_by_name($config->split($self->name(), 'require'));
    foreach my $obj (@{$self->{'requireobjs'}}) {
	$obj->start();
    }

    # run our own startup/execute functions
    $self->startup();
    $self->execute();
}

sub finish {
    my ($self) = @_;

    my $config = $self->config();

    # finish the execution by calling our own finish/cleanup first
    $self->finished();
    $self->cleanup();

    # then call the require's
    foreach my $obj (@{$self->{'requireobjs'}}) {
	$obj->finish();
    }

    # then call any 'after' tasks and execute them entirely
    $self->{'afterobjs'} =
	$self->collect_tasks_by_name($config->split($self->name(), 'after'));
    foreach my $obj (@{$self->{'afterobjs'}}) {
	$obj->start();
	$obj->finish();
    }
}

sub run {
    my ($self) = @_;
    $self->start();
    $self->finish();
}

# everyone should do this at least
sub describe {
    my ($self) = @_;
    my $subtype = $self;
    $subtype =~ s/TaskMaster::Task//;
    carp("The '$subtype' task does not know how to describe itself\n");
}

# not used unless over-ridden
sub init     { return 0; }      # called just after object creation
sub startup  { return 0; }
sub execute  { return 0; }
sub finished { return 0; }
sub cleanup  { return 0; }

# XXX: maybe in the future
sub pretest  { return 0; }
sub posttest { return 0; }

1;

=pod

=head1 NAME

TaskMastery::Task - Base class for the taskmastery tasks

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
