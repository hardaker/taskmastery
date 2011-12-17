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
