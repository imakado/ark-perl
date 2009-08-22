package Ark::Flow::Continue;

use Mouse;

use Data::UUID;
use Digest::SHA1 qw/ sha1_hex /;
use List::MoreUtils qw/ any /;

has 'namespace' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'flow_id' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

has 'context' => (
    is       => 'rw',
    isa      => 'Ark::Context',
    required => 1,
);

has 'is_init' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'state' => (
    is  => 'rw',
    isa => 'Str',
);

has 'attribute_holder' => (
    is        => 'rw',
    isa       => 'HashRef',
    default   => sub { +{} },
);

no Mouse;

sub BUILDARGS {
    my ($self, $args) = @_;
    
    return {
        flow_id => $args->{flow_id} ? $args->{flow_id} : $self->make_uid,
        namespace => $args->{namespace},
        context => $args->{context},
    };
}

sub get_instance {
    my $self = shift;
    my $args  = @_ > 1 ? {@_} : $_[0];

    my $namespace = $args->{namespace};
    die '$args->{namespace} must be string' unless length $namespace;

    my $context = $args->{context};
    my $flow_id = $context->request->param('flow_id') || '';
    
    my $instance = $context->session->get($self->make_session_key($namespace, $flow_id));

    if ($instance) {
        # update context
        $instance->context( $context );
        $instance->is_init(0);
    }
    else {
        $instance = __PACKAGE__->new($args);

        my $res = $context->response;
        $res->header('Cache-Control' => '');
        $res->header('Pragma' => '');

        $instance->is_init(1);        
    }

    return $instance;
}

sub is_happen_event {
    my $self = shift;
    my $event = shift;

    my $req = $self->context->request;

    return any { $req->param($_) } ($event, "${event}_x", "${event}_y");
}

sub get_state {
    shift->state
}

sub set_state {
    my $self = shift;
    $self->state($_[0]);
    $self->save;
}

sub get_flow_id {
    shift->flow_id
}

sub set_attribute {
    my ($self, $key, $attribute) = @_;
    
    $self->attribute_holder->{$key} = $attribute;
    $self->save;
}

sub remove_attribute {
    my ($self, $key) = @_;

    my $ret = delete $self->attribute_holder->{$key};
    $self->save;

    return $ret;
}

sub get_attribute {
    my $self = shift;
    my $key = shift;

    $self->attribute_holder->{$key}
}

sub has_attribute {
    my $self = shift;
    my $key = shift;

    exists $self->attribute_holder->{$key};
}

sub clear_attributes {
    my $self = shift;

    $self->attribute_holder( +{} );
    $self->save;
}

sub save {
    my $self = shift;
    my $key = $self->make_session_key( $self->namespace, $self->flow_id );

    $self->context->session->set( $key => $self);
}

sub make_uid {
    my $self = shift;
    my $len = shift;
    $len = 8 unless defined $len;

    my $uid = sha1_hex(Data::UUID->new->create);
    return substr $uid, 0, 8;
}

sub make_session_key {
    my $self = shift;
    my $namespace = shift;
    my $flow_id = shift;

    $flow_id = '' unless defined $flow_id;

    return $namespace . '/' . 'flow_continue' . '/' . $flow_id;
}

1;
