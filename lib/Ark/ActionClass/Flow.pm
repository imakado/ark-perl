package Ark::ActionClass::Flow;
use Mouse::Role;

has flow => (
    is  => 'rw',
    isa => 'Ark::Flow',
);

before ACTION => sub {
    my ($self, $action, @args) = @_;

    my $init_state = $action->attributes->{Flow}->[0]
        or return;

    my $namespace = $action->controller->can('NAMESPACE')
        ? $action->controller->NAMESPACE : $action->reverse;

    $self->context->ensure_class_loaded('Ark::Flow');

    my $flow = Ark::Flow->new({
        init_state => $init_state,
        namespace => $namespace,
        context => $self->context,
    });

    $self->flow( $flow );
    $self->context->stash->{flow} = $flow;
};

no Mouse::Role;

sub _parse_Flow_attr {
   my ($self, $name, $value) = @_;
   return Flow => $value;
}

1;


