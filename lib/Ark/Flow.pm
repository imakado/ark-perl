package Ark::Flow;

use Mouse;

use Ark::Flow::Continue;
use Ark::Flow::State;

has 'continue' => (
    is       => 'rw',
    isa      => 'Ark::Flow::Continue',
    required => 1,

    handles => [ qw( set_state get_attribute set_attribute
                     remove_attribute clear_attributes has_attribute  ) ],
);

has 'context' => (
    is       => 'rw',
    isa      => 'Ark::Context',
    required => 1,
);

has 'init_state' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'state_map' => (
    is       => 'rw',
    isa      => 'HashRef',
    default => sub { +{ } },
);  

no Mouse;

sub BUILDARGS {
    my $self = shift;
    my $args  = @_ > 1 ? {@_} : $_[0];
    
    die '$args->{init_state} is required' unless length $args->{init_state};
    die '$args->{namespace} is required' unless length $args->{namespace};

    my $continue = Ark::Flow::Continue->get_instance({
        namespace => $args->{namespace},
        context   => $args->{context},
    });

    if ($continue->is_init) {
        $continue->set_state( $args->{init_state} );
    }

    return {
        init_state => $args->{init_state},
        continue   => $continue,
        context    => $args->{context},
    };
}

sub get_template {
    my ($self) = @_;
    my $state_obj = $self->get_state_obj;
    
    return $state_obj->get_template;
}
  
sub execute {
    my $self = shift;

    $self->context->stash->{flow_id} = $self->get_continue->get_flow_id;

    return $self->context->forward( $self->get_executable_action_name );
}

sub get_executable_action_name {
    my $self = shift;

    my $state_obj = $self->get_state_obj;
    my $event_map = $state_obj->event_map;

    while (my ($event_name, $action_name) = each %$event_map) {
        if ( $self->continue->is_happen_event( $event_name ) ) {
            return $action_name;
        }
    }
}

sub get_state_obj {
    my $self = shift;
    my $state_name = $self->continue->get_state;
    my $state_obj = $self->state_map->{$state_name};

    die sprintf('The state [%s] is not registered.', $state_name) unless defined $state_obj;

    return $state_obj;
}

sub add_event {
    my ($self, $state, $event, $callback) = @_;

    my $state_obj = $self->state_map->{$state};
    
    $state_obj->add_event($event, $callback);

    return $self;
}
  
sub remove_event {
    my ($self, $state, $event) = @_;

    my $state_obj = $self->state_map->{$state};

    unless ( $state_obj ) {
        die sprintf('The state [%s] is not registered.', $state);
    }

    $state_obj->remove_event($event);

    return $self;
}

sub add_state {
    my ($self, $state, $template) = @_;

    $self->state_map->{$state} = Ark::Flow::State->new({
        state => $state,
        template => $template,
    });

    return $self;
}

sub remove_state {
    my $self = shift;
    my $state = shift;
    delete $self->state_map->{$state};

    return $self;
}

sub get_continue {
    return shift->continue;
}

1;
