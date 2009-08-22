use Test::Base;
plan 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lib";

use Ark::Test 'T';
use HTTP::Request::Common;

use Smart::Comments;
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
    
}
