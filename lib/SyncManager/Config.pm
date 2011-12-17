package SyncManager::Config;

use Carp;

use strict;

our $VERSION = "0.1";

my $DEFNAME = "__DEFAULT__";

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    bless($self, $class);
    return $self;
}

sub read_config {
    my ($self, $file) = @_;

    my $token = $DEFNAME;

    $file ||= "$ENV{HOME}/.syncmanager";
    
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
