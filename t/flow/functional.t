use Test::Base;
plan 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lib";

use Ark::Test 'T';
use HTTP::Request::Common;

use Test::MockObject::Extends;

{
    my ($res, $c) = ctx_get('/');

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow') ;
    
    isa_ok( my $cont = $flow->get_continue , 'Ark::Flow::Continue' );
    
    $cont->set_state('here');
    ok($cont->get_state, 'set_state  and get_state ok');
    ok($cont->flow_id, 'flow id ok');
    
    $cont->set_attribute( 'k' => { ruby => 'good', perl => 'good'} );
    is_deep( $cont->get_attribute('k'),  { ruby => 'good', perl => 'good'}, 'get_attribute'  );
    
    $cont->remove_attribute('k');
    ok(! $cont->get_attribute('k') );
    
    $cont->set_attribute( 'i' => { never => 'give', up => 'man'} );
    ok( $cont->has_attribute('i') );
    
    $cont->set_attribute('other' => 'hehe');
    
    $cont->clear_attributes;

    ok( ! $cont->get_attribute('k'), 'cleared');
    ok( ! $cont->get_attribute('i'), 'cleared');

    isa_ok( $cont->attribute_holder , 'HASH');


    # test for input type="image" bug
    # when param event_name_x is 0, is_happen_event returns false.
    # in this case, should return true.

    # this probrem issue when click most left or top of <input type="image"...> submit button.
    {
        my $context_mock = Test::MockObject::Extends->new( $cont->context );
        $context_mock->mock( request => sub {
            my $hsh = { event_x => 0, };

            my $m = Test::MockObject->new;
            return $m->mock( param => sub {
                my $self = shift;
                $hsh->{$_[0] }
            });
        } );
    
        $cont->context( $context_mock );

        ok($cont->is_happen_event('event'), 'true even if $context->req->param("event_x") is 0');
    }

    {
        my $context_mock = Test::MockObject::Extends->new( $cont->context );
        $context_mock->mock( request => sub {
            my $hsh = { event_y => 0, };

            my $m = Test::MockObject->new;
            return $m->mock( param => sub {
                my $self = shift;
                $hsh->{$_[0] }
            });
        } );
    
        $cont->context( $context_mock );

        ok($cont->is_happen_event('event'), 'true even if $context->req->param("event_y") is 0');
    }
}
