package TaskMastery::Task;

use TaskMastery;
use Carp;
use strict;

our $VERSION = "0.1";
our @ISA = qw(TaskMastery);

sub set_directory {
    my ($self) = @_;
    my $config = $self->config();
    my $directory = $config->get($self->name(), 'directory');
    chdir($directory) if (defined($directory) && $directory ne '');
}

sub start {
    my ($self) = @_;

    return if ($self->{'stoppedat'});

    my $config = $self->config();

    $self->set_directory();

    # find 'before' childen and execute them entirely
    $self->{'beforeobjs'} =
	$self->collect_tasks_by_name([$config->split($self->name(), 'before')]);
    if (defined($self->{'beforeobjs'})) {
	foreach my $obj (@{$self->{'beforeobjs'}}) {
	    if ($obj->run() && $self->fail('beforeobjs::run')) {
		return 1;
	    }
	}
    }

    # find 'require' childen and execute just their start routines
    $self->{'requireobjs'} =
	$self->collect_tasks_by_name([$config->split($self->name(), 'require')]);
    if (defined($self->{'requireobjs'})) {
	foreach my $obj (@{$self->{'requireobjs'}}) {
	    if ($obj->start() && $self->fail('requireobjs::start')) {
		return 1;
	    }
	}
    }

    # run our own startup/execute functions
    if ($self->startup() && $self->fail('startup')) {
	return 1;
    }
    return $self->execute() && $self->fail("execute");
}

sub finish {
    my ($self) = @_;

    return if ($self->{'stoppedat'});

    my $config = $self->config();

    $self->set_directory();

    # finish the execution by calling our own finish/cleanup first
    if ($self->finished() && $self->fail('finished')) {
	return 1;
    }

    # then call the require's finish and clean
    if (defined($self->{'requireobjs'})) {
	foreach my $obj (@{$self->{'requireobjs'}}) {
	    if ($obj->finish() && $self->fail('requireobjs::finish')) {
		return 1;
	    }
	    if ($obj->clean() && $self->fail('beforeobjs::clean')) {
		return 1;
	    }
	}
    }

    # then call any 'after' tasks and execute them entirely
    $self->{'afterobjs'} =
	$self->collect_tasks_by_name([$config->split($self->name(), 'after')]);
    if (defined($self->{'afterobjs'})) {
	foreach my $obj (@{$self->{'afterobjs'}}) {
	    if ($obj->run() && $self->fail('afterobjs::run')) {
		return 1;
	    }
	}
    }
}

sub clean {
    my ($self) = @_;

    return if ($self->{'stoppedat'});

    $self->set_directory();

    # final cleanup step calling only our own cleanup function
    return $self->cleanup() && $self->fail("cleanup");
}

sub run {
    my ($self) = @_;

    my $config = $self->config();

    if ($self->start() && $self->fail('start')) {
	return 1;
    }
    if ($self->finish() && $self->fail('finish')) {
	return 1;
    }
    return $self->clean() && $self->fail("clean");
}

sub fail {
    my ($self, $spot) = @_;

    my $config = $self->config();
    my $onfailure = $config->get($self->name(), 'onfailure', 'continue');
    my $silent = $config->get($self->name(), 'silent');

    if (!defined($silent) && $silent ne '1' && $silent ne "yes") {
	print STDERR "task $self->{name}::$spot failed (action: $onfailure)\n";
    }
    $self->{'failure_' . $spot} = 1;

    if ($onfailure eq 'stop') {
	$self->{'stoppedat'} = $spot;
	return 1;
    }
    return 0;
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
