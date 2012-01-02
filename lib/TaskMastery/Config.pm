package TaskMastery::Config;

use TaskMastery;
use Carp;
use strict;
use Cwd;
use IO::File;

our @ISA = qw(TaskMastery);

our $VERSION = "0.1";

my $DEFNAME = "__DEFAULT__";

sub read_config {
    my ($self, $file) = @_;

    my $token = $DEFNAME;
    my $config_order = 1;

    # set some global starting defaults
    $self->{'config'}{$DEFNAME} = {
	'directory'   => getcwd(),
	'interactive' => can_be_interactive(),
	'__order' => $config_order++,
    };

    # read in the config file
    $file ||= "$ENV{HOME}/.taskmastery";

    $self->open_file($file, \$token, \$config_order);
}

sub open_file {
    my ($self, $file, $token, $config_order) = @_;

    my $fh = new IO::File;
    if (! $fh->open("< $file")) {
	print STDERR "failed to open and read $file\n";
	# XXX: log error
	return 1;
    }
    while(<$fh>) {
	next if (/^\s*#/);
	next if (/^\s*$/);

	if (/^\s*include ["'](.*)["']/) {     # matches "include 'foo'"
	    $self->open_file($1, $token, $config_order);
	} elsif (/^\s*\[(.*)\]\s*$/) {	      # matches lines like " [foo] "
	    $$token = $1;
	    $self->{'config'}{$$token}{'__order'} = ${$config_order}++;
	} elsif (/^\s*(\w+)\s*[:=]\s*(.*)/) { # matches lines like foo=bar
	    $self->{'config'}{$$token}{$1} = $2;
	} else {
	    # XXX: broken line???  report this!
	}
    }
    return 0;
}

sub get {
    my ($self, $token, $key, $default) = @_;
    return if (!exists($self->{'config'}{$token})); # don't auto-create

    # return the value if we have it
    if (exists($self->{'config'}{$token}{$key})) {
	return $self->{'config'}{$token}{$key};
    }

    # else fall back to a default value, if possible
    if (exists($self->{'config'}{$DEFNAME}) &&
	exists($self->{'config'}{$DEFNAME}{$key})) {
	return $self->{'config'}{$DEFNAME}{$key};
    }

    # finally fall back to the supplied default
    return $default;
}    

sub set {
    my ($self, $token, $key, $value) = @_;
    $self->{'config'}{$token}{$key} = $value;
}

sub exact_split {
    my ($self, $token, $key, $split) = @_;
    my $val = $self->get($token, $key);
    return if (!defined($val));
    return (split(/$split/, $val));
}

sub split {
    my ($self, $token, $key, $split) = @_;
    $split ||= ",";
    return ($self->exact_split($token, $key, "\\s*" . $split . "\\s*"));
}

sub get_names {
    my ($self) = @_;
    my $config = $self->{'config'};
    return [sort { $config->{$a}{'__order'} <=> $config->{$b}{'__order'} }
	    keys(%{$config})];
}

sub can_be_interactive {
  return -t STDIN && -t STDOUT;
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
