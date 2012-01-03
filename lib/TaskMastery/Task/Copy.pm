package TaskMastery::Task::Copy;

use TaskMastery::Task;
use Carp;
use strict;

our @ISA = qw(TaskMastery::Task);

our $VERSION = "0.1";

sub init {
    my ($self) = @_;

    # transform ourselves into the new object type
    my $config   = $self->config();
    my $name = $self->name();
    my $origtype = $config->get($name, 'type');
    my $from     = $config->get($name, 'from');
    my $newtype  = $config->get($from, 'type');

    # copy the config tokens over (and modify them as appropriate)
    foreach my $key (keys(%{$config->{'config'}{$from}})) {
	$config->{'config'}{$name}{$key} = $config->{'config'}{$from}{$key};
    }
    $config->{'config'}{$name}{'type'} = $newtype;

    # create the new object, which will call it's init() routine...
    my $newobj = $self->create_task_object($name);

    return $newobj;
}

1;

=pod

=head1 NAME

TaskMastery::Task::Copy - Creates a copy from another item

=head1 AUTHOR

Wes Hardaker <opensource@hardakers.net>

=head1 COPYRIGHT and LICENSE

Copyright Wes Hardaker, 2011

GPLv2
