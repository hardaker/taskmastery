package TaskMastery::Config;

use TaskMastery;
use Carp;
use strict;

our @ISA = qw(TaskMastery);

our $VERSION = "0.1";

my $DEFNAME = "__DEFAULT__";

sub read_config {
    my ($self, $file) = @_;

    my $token = $DEFNAME;

    $file ||= "$ENV{HOME}/.taskmastery";
    
    open(I, "$file") || croak("failed to open $file");
    while(<I>) {
	# matches lines like " [foo] "
	if (/^\s*\[(.*)\]\s*$/) {
	    $token = $1;
	} elsif (/^\s*(\w+):\s*(.*)/) {
	    $self->{'config'}{$token}{$1} = $2;
	}
    }
}

sub get {
    my ($self, $token, $key) = @_;
    return if (!exists($self->{'config'}{$token})); # don't auto-create

    # return the value if we have it
    if (exists($self->{'config'}{$token}{$key})) {
	return $self->{'config'}{$token}{$key};
    }

    # else fall back to a default value, if possible
    return if (!exists($self->{'config'}{$DEFNAME}));

    return if (!exists($self->{'config'}{$DEFNAME}{$key}));

    return $self->{'config'}{$DEFNAME}{$key};
}    

sub exact_split {
    my ($self, $token, $key, $split) = @_;
    my $val = $self->get($token, $key);
    return if (!defined($val));
    return (split(/$split/, $val));
}

sub split {
    my ($self, $token, $key, $split) = @_;
    return ($self->exact_split($token, $key, "\\s*" . $split . "\\s*"));
}

1;

=pod

=head1 NAME

TaskMastery::Config - read in a taskmaster config file

=head1 DESCRIPTION

This module reads in task master config files and offers an API for
accessing the data.

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
