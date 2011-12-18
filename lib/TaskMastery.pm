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

    # copy in the singular config object for the whole system
    $obj->{'configobj'} = $config;
    $obj->{'name'} = $taskname;

    # let it do any initialization beyond the new() call
    $obj->init();

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

sub collect_tasks_by_name {
    my ($self, $tasknames) = @_;
    my @objects;
    my $config = $self->config();

    my $obj;
    foreach my $taskname (@$tasknames) {
	# if a name is prefixed by a 'tag:' string then it should collect 
	# everything it can find that is tagged.

	if ($taskname =~ /tag:\s*(.*)/) {
	    my $tag = $1;
	    foreach my $name (@{$config->get_names()}) {
		foreach my $tasktag ($config->split($name, 'tag')) {
		    if ($tasktag eq $tag) {
			push @objects, $self->create_task_object($name);
			last;
		    }
		}
	    }
	} else {
	    $obj = $self->create_task_object($taskname);
	    push @objects, $obj;
	}
    }
    return \@objects;
}

sub name {
    my ($self) = @_;
    return if (!exists($self->{'name'}));
    return $self->{'name'};
}

sub run_tasks {
    my ($self, @tasks) = @_;
    my $objs = $self->collect_tasks_by_name(\@tasks);
    foreach my $obj (@$objs) {
	$obj->run();
    }
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

=head1 TASK FLOW ARCHITECTURE

Each task will perform the following operations.  Not all task types
make use of them all, however.

  - Run the task's init() routine
  - Run any tasks identified by the 'before' configuration token (push to T)
  - XXX Run any tasks identified by the 'before-tag' tag references (push to T)
  - Run the task's startup() routine
  - Run the task type's execute()
  - Return to parent to have them execute()
  - Run the task's finished() routine
  - Run any objects in T that have finished() routines
  - Run any 'after' references
  - Run any 'after-tag' tag references
  - Run the task's cleanup() routine

Or more condensed:

 - task's init:
 - run everithing in before:
 - run startup/execute in require:
 - run execute, finished
 - run execute/finished in require:
 - run everything in after:

The goal of the above complex series of steps is to allow for:

  - Parent's to require actions from a child
  - Parent's to depend on both startup and finished actions to happen
    before and after the parent's task itself.

=head1 SEE ALSO

taskmastery(1)

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
