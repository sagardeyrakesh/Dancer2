# ABSTRACT: TODO

package Dancer::Core::Role::Server;
use Moo::Role;

use Carp 'croak';
use File::Spec;

use Dancer::Moo::Types;

use Dancer::Core::App;
use Dancer::Core::Dispatcher;
use Dancer::Core::Response;
use Dancer::Core::Request;
use Dancer::Core::Context;

has name => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_name',
);

has host => (
    is => 'rw',
    isa => sub { Str(@_) },
    required => 1,
);

has port => (
    is => 'rw',
    isa => sub { Num(@_) },
    required => 1,
);

has is_daemon => (
    is => 'rw',
    isa => sub { Bool(@_) },
);

has apps => (
    is => 'ro',
    isa => sub { ArrayRef(@_) },
    default => sub { [] },
);

has runner => (
    is => 'ro',
    required => 1,
    isa => sub { ObjectOf('Dancer::Core::Runner', @_) },
    weak_ref => 1,
);

# The dispatcher to dispatch an incoming request to the appropriate route
# handler
has dispatcher => (
    is => 'rw',
    isa => sub { ObjectOf('Dancer::Core::Dispatcher', @_) },
    lazy => 1,
    builder => '_build_dispatcher',
);

requires '_build_name';

sub _build_dispatcher {
    my ($self) = @_;
    my $d = Dancer::Core::Dispatcher->new();
    $d->apps( $self->apps );
    return $d;
}

# our PSGI application
sub psgi_app {
    my ($self) = @_;
    sub {
        my ($env) = @_;
        $self->dispatcher->dispatch($env)->to_psgi;
    };
}

sub register_application {
    my ($self, $app) = @_;
    push @{ $self->apps }, $app;
    $app->server($self);
    $app->server->runner->postponed_hooks({
        %{ $app->server->runner->postponed_hooks },
        %{ $app->postponed_hooks }
    });
}

1;
