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
	'__order'     => $config_order++,
	'type'        => 'command',
    };

    # read in the config file
    $file ||= "$ENV{HOME}/.taskmastery";

    $self->open_file($file, \$token, \$config_order);
}

sub open_file {
    my ($self, $origfile, $token, $config_order) = @_;

    my @files = ($origfile);

    if ($origfile =~ /\*/) {
	# globbing
	@files = glob($origfile);
    }

    foreach my $file (@files) {
	my $fh = new IO::File;
	if (! $fh->open("< $file")) {
	    print STDERR "failed to open and read $file\n";
	    # XXX: log error
	    return 1;
	}
	
      readLine:
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
		my $what = $2;
		my $stepName = $1;
		while ($what =~ s/\\$//) {
		    $what = <$fh>;
		    last readLine if (!defined($what));

		    $self->{'config'}{$$token}{$stepName} .=
			"; " . $what;
		}
	    } else {
		# XXX: broken line???  report this!
	    }
	}
    }
    return 0;
}

sub get {
    my ($self, $token, $key, $default) = @_;
    return if (!exists($self->{'config'}{$token})); # don't auto-create

    my $result;

    if (exists($self->{'config'}{$token}{$key})) {
	# return the value if we have it
	$result = $self->{'config'}{$token}{$key};

    } elsif (exists($self->{'config'}{$DEFNAME}) &&
	exists($self->{'config'}{$DEFNAME}{$key})) {
	# else fall back to a system-wide default value, if possible
	$result = $self->{'config'}{$DEFNAME}{$key};

    } else {
	# finally fall back to the supplied default
	$result = $default || "";
    }

    # replace [[FOO]] with a parameter value named FOO
    $result =~ s/\[\[([^\]]+)\]\]/$self->get_parameter($1)/ge;

    return $result;
}    

sub get_parameter {
    # XXX: determine if interactive or not...
    my ($self, $name) = @_;

    if (!exists($self->{'parameters'}{$name})) {
	if ($self->can_be_interactive()) {
	    my $result = 
		$self->get_input("Enter a value for parameter \"$name\":\n> ");
	    $self->{'parameters'}{$name} = $result;
	} else {
	    croak("undefinied parameter \"$name\" can't be found\n");
	}
	# XXX: prompt
    }
    return $self->{'parameters'}{$name};
}

sub set_parameter {
    my ($self, $name, $value) = @_;

    $self->{'parameters'}{$name} = $value;
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
    $split ||= "[;,]";
    return ($self->exact_split($token, $key, "\\s*" . $split . "\\s*"));
}

sub get_names {
    my ($self) = @_;
    my $config = $self->{'config'};
    return [sort {
	(exists($config->{$a}{'__order'}) ? $config->{$a}{'__order'} : 0) <=>
	(exists($config->{$b}{'__order'}) ? $config->{$b}{'__order'} : 0) }
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
