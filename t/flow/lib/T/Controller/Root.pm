package T::Controller::Root;
use Ark 'Controller';

has '+namespace' => default => '';

with 'Ark::ActionClass::Flow';

sub index :Path :Args(0) :Flow('input') { # :Flow(init_state)
    my ($self, $c) = @_;
    
    $self->flow->add_state('input', 'signup/index') # or $c->stash->{flow}->add_state
               ->add_state('confirm', 'signup/confirm') # can chain
               ->add_state('complete', 'signup/complete');

    $self->flow->add_event('input',   'confirm_submit', 'confirm')
               ->add_event('input',   'back_submit',    'input')
               ->add_event('confirm', 'back_submit',    'input')
               ->add_event('confirm', 'complete_submit',  'complete');

    $self->flow->set_attribute( 'flow_init', 1);

    $self->flow->execute;

    #$c->view('MT')->template( $self->flow->get_template );
}

sub validate :Private {
    my ($self, $params) = @_;
    return ( $params->{required_param} ) ? 1 : 0;
}

sub input :Private {
    my ($self, $c) = @_;

    $c->stash->{called_input} = 1;
    $self->flow->set_state('input');
}

sub confirm :Private {
    my ($self, $c) = @_;

    my $params = $c->req->params;

    if ( $self->validate( $params ) ) {
        $c->stash->{is_valid} = 1;
        $self->flow->set_attribute( 'test_set_attribute_hash', { hoge => 'hoge', huga => 'huga', });
        $self->flow->set_attribute( 'values',  $c->req->param('save_param') );
        $self->flow->set_state('confirm');
    }
    else {
        # validation failed go back to input.
        $c->stash->{is_valid} = 0;
        $self->flow->set_state('input');
    }
}

sub complete :Private {
    my ($self, $c) = @_;

    $c->stash->{completed} = 1;

    $c->stash->{values} = $self->flow->get_attribute( 'values' );
    $c->stash->{test_set_attribute_hash} = $self->flow->get_attribute( 'test_set_attribute_hash' );

    $self->flow->remove_attribute('test_set_attribute_hash');
    $self->flow->remove_attribute('values');
    $self->flow->set_state('complete');
}

1;

