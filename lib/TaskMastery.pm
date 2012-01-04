package TaskMastery;

use Carp;
use strict;
use Cwd;

use TaskMastery::Config;

our $VERSION = "0.1";

our %tasks; # stores the already created tasks

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
    my ($self, $taskname, $dryrun) = @_;
    my $config = $self->config();
    my $dryrun2 = (!defined($dryrun) || $dryrun eq '' ? $dryrun : " " . $dryrun) ;

    if (exists($self->{'tasks'}{$taskname}) &&
	!$config->get($taskname, 'multiple')) {
	return $self->{'tasks'}{$taskname};
    }
    
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
    $obj->{'tasks'} = $self->{'tasks'};

    # let it do any initialization beyond the new() call
    # (possibly replacing itself with a new object)
    my $newobj = $obj->init($dryrun2);
    if ($newobj) {
	$obj = $newobj;
    }

    $self->{'tasks'}{$taskname} = $obj;

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
    my ($self, $tasknames, $dryrun) = @_;
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
			push @objects, $self->create_task_object($name, $dryrun);
			last;
		    }
		}
	    }
	} else {
	    $obj = $self->create_task_object($taskname, $dryrun);
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

    my $dryrun = '';
    my $options;

    $options = shift @tasks if ($#tasks > -1 && ref($tasks[0]) eq 'HASH');

    if (ref($options) eq 'HASH' && $options->{'dryrun'}) {
	$dryrun = "-";
    }

    my $objs = $self->collect_tasks_by_name(\@tasks, $dryrun);

    foreach my $obj (@$objs) {
	$obj->run($dryrun);
    }
    $self->clear_tasks(); # erase the created object list
}

sub clear_tasks {
    my ($self) = @_;
    %{$self->{'tasks'}} = ();
}

sub get_input {
    my ($self, $prompt) = @_;
    print "$prompt " if ($prompt);
    my $bogus = <STDIN>;
    chomp($bogus);
    return $bogus;
}

sub get_crq {
    my ($self, $description, $prompt, $validitytest) = @_;

    my $config = $self->config();
    if (! $config->get($self->name(), 'interactive')) {
	return '-';
    }

    print "----------------------------------------\n";
    print "Failure!\n";
    print "Task:\t\t"      . $self->name() . "\n";
    print "Directory:\t" . getcwd() . "\n";
    print "$description\n" if ($description);

    while (1) {
	my $input =
	    $self->get_input($prompt || "Retry, Continue, Stop this task, Quit (r,c,s,q): ");
	if ($validitytest) {
	    $input =~ lc($input);
	    if ($input =~ /$validitytest/) {
		return $input;
	    }
	} else {
	    return 'r' if ($input =~ /^r/i);
	    return 'c' if ($input =~ /^c/i);
	    return 'q' if ($input =~ /^q/i);
	    return 's' if ($input =~ /^s/i);
	}
	print "Error: invalid input\n";
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
  - Return to parent to have them execute(), and finished()
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
 - run execute/finished/cleanup in require:
 - run everything in after:
 - run cleanup

The goal of the above complex series of steps is to allow for:

  - Parent's to require actions from a child
  - Parent's to depend on both startup and finished actions to happen
    before and after the parent's task itself.

A broken down example containing one parent and children:

  - parent's init()
    # before tasks
    - before child1's init()
    - before child1's startup()
    - before child1's execute()
    - before child1's finished()
    - before child1's cleanup()
    - before child2's init()
    - before child2's startup()
    - before child2's execute()
    - before child2's finished()
    - before child2's cleanup()
    # require tasks
    - require child1's init()
    - require child1's startup()
    - require child1's execute()
    - require child2's init()
    - require child2's startup()
    - require child2's execute()
  - parent's startup()
  - parent's execute()
  - parent's finished()
    # require tasks wrapup
    - require child1's finished()
    - require child1's cleanup()
    - require child2's finished()
    - require child2's cleanup()
    # after tasks
    - after child1's init()
    - after child1's startup()
    - after child1's execute()
    - after child1's finished()
    - after child1's cleanup()
    - after child2's init()
    - after child2's startup()
    - after child2's execute()
    - after child2's finished()
    - after child2's cleanup()
  - parent's cleanup()

=head1 SEE ALSO

taskmastery(1)

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
