package TaskMastery::Task;

use TaskMastery;
use Carp;
use strict;
use IO::File;

our $VERSION = "0.1";
our @ISA = qw(TaskMastery);

sub set_directory {
    my ($self) = @_;
    my $config = $self->config();
    my $directory = $self->get_config('directory');
    chdir($directory) if (defined($directory) && $directory ne '');
}

sub start {
    my ($self, $dryrun) = @_;

    return if ($self->{'stoppedat'});

    my $config = $self->config();
    my $dryrun2 = $self->get_next_dryrun_flag($dryrun);

    $self->dryrun($dryrun, "Starting: $self->{name}") if ($dryrun);

    if ($self->check_skipif($dryrun2)) {
	$self->{'stoppedat'} = 1;
	return 0; # not a failure
    }


    $self->{'refcount'}++;
    $self->{'refcleancount'}++;

    # don't let a task object start multiple times
    # (note: multiple objects will be created if multiple:1 is set)
    return if ($self->{'started'});
    $self->{'started'} = 1;

    $self->set_directory();

    # find 'before' childen and execute them entirely
    $self->{'beforeobjs'} =
	$self->collect_tasks_by_name([$self->split_config('before')],
				     $dryrun2);
    if (defined($self->{'beforeobjs'})) {
	foreach my $obj (@{$self->{'beforeobjs'}}) {
	    if ($obj->run($dryrun2) && $self->fail('beforeobjs::run')) {
		return 1;
	    }
	}
    }

    # find 'require' childen and execute just their start routines
    $self->{'requireobjs'} =
	$self->collect_tasks_by_name([$self->split_config('require')],
				     $dryrun2);
    if (defined($self->{'requireobjs'})) {
	foreach my $obj (@{$self->{'requireobjs'}}) {
	    if ($obj->start($dryrun2) && $self->fail('requireobjs::start')) {
		return 1;
	    }
	}
    }

    # run our own startup/execute functions
    if ($self->startup($dryrun2) && $self->fail('startup')) {
	return 1;
    }
    return $self->execute($dryrun2) && $self->fail("execute");
}

sub finish {
    my ($self, $dryrun) = @_;

    $self->{'refcount'}--;
    return if ($self->{'refcount'} > 0);

    return if ($self->{'stoppedat'});

    return if ($self->{'finished'});
    $self->{'finished'} = 1;

    my $config = $self->config();
    my $dryrun2 = $self->get_next_dryrun_flag($dryrun);

    $self->dryrun($dryrun, "Finishing: $self->{name}") if ($dryrun);

    $self->set_directory();

    # finish the execution by calling our own finish/cleanup first
    if ($self->finished($dryrun2) && $self->fail('finished')) {
	return 1;
    }

    # then call the require's finish and clean
    if (defined($self->{'requireobjs'})) {
	foreach my $obj (@{$self->{'requireobjs'}}) {
	    if ($obj->finish($dryrun2) && $self->fail('requireobjs::finish')) {
		return 1;
	    }
	    if ($obj->clean($dryrun2) && $self->fail('beforeobjs::clean')) {
		return 1;
	    }
	}
    }

    # then call any 'after' tasks and execute them entirely
    $self->{'afterobjs'} =
	$self->collect_tasks_by_name([$self->split_config('after')],
				     $dryrun2);
    if (defined($self->{'afterobjs'})) {
	foreach my $obj (@{$self->{'afterobjs'}}) {
	    if ($obj->run($dryrun2) && $self->fail('afterobjs::run')) {
		return 1;
	    }
	}
    }
}

sub clean {
    my ($self, $dryrun) = @_;

    $self->{'refcleancount'}--;
    return if ($self->{'refcleancount'} > 0);

    return if ($self->{'stoppedat'});

    return if ($self->{'cleaned'});
    $self->{'cleaned'} = 1;
    my $dryrun2 = $self->get_next_dryrun_flag($dryrun);

    $self->dryrun($dryrun, "Cleaning: $self->{name}") if ($dryrun);
    $self->set_directory();

    # final cleanup step calling only our own cleanup function
    return $self->cleanup($dryrun2) && $self->fail("cleanup");
}

sub run {
    my ($self, $dryrun) = @_;

    my $config = $self->config();
    my $dryrun2 = $self->get_next_dryrun_flag($dryrun);

    if ($self->start($dryrun2) && $self->fail('start')) {
	return 1;
    }
    if ($self->finish($dryrun2) && $self->fail('finish')) {
	return 1;
    }
    return $self->clean($dryrun2) && $self->fail("clean");
}

sub fail {
    my ($self, $spot) = @_;

    my $config = $self->config();
    my $onfailure = $self->get_config('onfailure', 'prompt');
    my $silent = $self->get_config('silent');

    if (!defined($silent) && $silent ne '1' && $silent ne "yes") {
	print STDERR "task $self->{name}::$spot failed (action: $onfailure)\n";
    }
    $self->{'failure_' . $spot} = 1;

    if ($onfailure eq 'stop') {
	$self->{'stoppedat'} = $spot;
	return 1;
    }
    if ($onfailure eq 'prompt') {
	my $ans = $self->get_crq("Spot:\t\t$spot");
	if ($ans eq 'q') {
	    print "Quitting at your your request...\n";
	    exit(1);
	}
	if ($ans eq 'c' || $ans eq '-') {
	    # the default is to continue; forced stop onfailure contions
	    # are caught before this (above), which means we can
	    # safely continue at this point.
	    return 0; # ignore the error
	}
	if ($ans eq 's') {
	    # force stopping of this task
	    $config->set($self->name(), 'onfailure', 'stop');
	    return 1;
	}
	return -1;    # retry
    }
    return 0;
}

sub dryrun_prefix {
    my ($self, $dryrun) = @_;
    return sprintf("%-10.10s %-15.15s ", $dryrun || "", $self->name());
}

sub dryrun {
    my ($self, $dryrun, $msg) = @_;
    print $self->dryrun_prefix($dryrun), $msg, "\n";
}

######################################################################
# description services
#
sub describe {
    my ($self, $options) = @_;
    if (defined($options->{'dot'})) {
	$self->describe_png($options);
    } else {
	$self->describe_generic($options);
    }
}

sub describe_png {
    my ($self, $options) = @_;
    foreach my $position (qw(before require after)) {
	my $label;
	if ($position ne 'require') {
	    $label = $position;
	    $label =~ s/(.).*/$1/;
	    $label = "[label=$label]";
	}
	my $objs = $self->collect_tasks_by_name([$self->split_config($position)]);
	foreach my $obj (@$objs) {
	    my $fh = $options->{'dot'};
	    print $fh "  \"$self->{name}\" -> \"$obj->{name}\" $label\n";
	    $obj->describe_png($options);
	}
    }
}

sub describe_generic {
    my ($self, $options) = @_;
#    use Data::Dumper;
#    print Dumper($self);
    $self->describe_title();
    $self->describe_contents($self->describe_generic_keywords());
    $self->describe_contents();
    if (defined($options->{'recursive'})) {
	my $savethis = $options->{'recursive'};
	$options->{'recursive'} .= $self->{'name'} . " -> ";
	foreach my $position (qw(before require after)) {
	    my $objs = $self->collect_tasks_by_name([$self->split_config($position)]);
	    if (defined($objs) && $#$objs > -1) {
		print("# $options->{'recursive'} $position\n");
	    }
	    foreach my $obj (@$objs) {
		$obj->describe($options);
	    }
	}
	$options->{'recursive'} = $savethis;
    }
}

sub describe_title {
    my $self = shift;
    print "[$self->{name}]\n";
    $self->print_keyword('type');
}

sub describe_contents {
    my $self = shift;
    my @keywords = @_;
    if ($#keywords == -1) {
	@keywords = $self->describe_keywords();
    }
#    print "  # keywords: " . join(", ", @keywords). "\n";
    foreach my $keyword (@keywords) {
	if ($self->get_config($keyword)) {
	    $self->print_keyword($keyword);
	}
    }
}

sub print_keyword {
    my ($self, $keyword) = @_;
    printf("  %-15.15s %s\n", $keyword . ":", $self->get_config($keyword));
}

sub describe_generic_keywords {
    return qw(directory require before after onfailure silent);
}

sub describe_keywords {
    return ();
}


# not used unless over-ridden
sub init     { return 0; }      # called just after object creation
sub startup  { return 0; }
sub execute  { return 0; }
sub finished { return 0; }
sub cleanup  { return 0; }
sub skipif   { return 0; }

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
