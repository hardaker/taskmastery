package TaskMastery;

use Carp;
use strict;

use TaskMastery::Config;

our $VERSION = "0.1";

# note: many sub-modules depend on this routine as a generic new() routine
sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    bless($self, $class);
    return $self;
}

sub read_config {
    my ($self, $object) = @_;
    if (!defined($self->{'configobj'})) {
	$self->{'configobj'} = new TaskMastery::Config;
    }
    $self->{'configobj'}->read_config($object);
}

sub config {
    my ($self) = @_;
    return $self->{'configobj'};
}

sub create_task_object {
    my ($self, $taskname) = @_;
    my $config = $self->config();
    
    # pull out the type
    my $type = $config->get($taskname, 'type');

    if (!defined($type)) {
	croak "failed to find a task type for task '$taskname'";
    }

    # manipulate it to be a single UC char followed by the rest lc
    $type =~ s/(.)(.*)/uc($1) . lc($2)/e;

    # now create an object based on a module name of that type
    my $obj = $self->create_object_of_type($type);
    return $obj;
}

sub create_object_of_type {
    my ($self, $type) = @_;

    # test that we can load it
    my $evalresult = eval "require TaskMastery::Task::$type;";
    if (!$evalresult) {
	croak "Failed to load an object for a task type of '$type'";
    }

    my $obj = eval "new TaskMastery::Task::$type;";
    if (ref($obj) ne "TaskMastery::Task::$type") {
	croak "The created object is not of the right type (expected '$type')";
    }

    return $obj;
}

1;

=pod

=head1 NAME

TaskMastery - Base class for the taskmastery system

=head1 SYNOPSIS

  # create the parent object
  my $tm = new TaskMastery();

  # read in the config file
  $tm->read_config("/path/to/foo.conf");

  # run commands
  $tm->run(name => "taskname");
  $tm->run(tag => "tagname");

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
