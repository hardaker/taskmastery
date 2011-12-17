package TaskMastery;

use Carp;
use strict;

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

1;

=pod

=head1 NAME

TaskMastery - Base class for the taskmastery system

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
