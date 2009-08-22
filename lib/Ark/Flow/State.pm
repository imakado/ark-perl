package Ark::Flow::State;

use Mouse;

has 'template' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'state' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'event_map' => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => sub { +{} },
);

sub BUILDARGS {
    my ($self, $args) = @_;

    return {
        state => $args->{state},
        template => $args->{template} ? $args->{template} : $args->{state},
    };
}

no Mouse;

sub get_template {
    return shift->template;
}

sub get_state {
    return shift->state;
}

sub add_event {
    my ($self, $event, $action_name) = @_;
    $self->event_map->{$event} = $action_name;
}

sub remove_event {
    my $self = shift;
    my $event = shift;

    delete $self->event_map->{$event};
}

1;
