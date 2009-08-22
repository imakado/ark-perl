use Test::Base;
plan 'no_plan';

use FindBin;
use lib "$FindBin::Bin/lib";

use Ark::Test 'T';
use HTTP::Request::Common;

my $FLOW_ID;
my $COOKIE;

{
    my ($res, $c) = ctx_get('/');

    my $flow = $c->stash->{flow};

    isa_ok($flow, 'Ark::Flow');

    is($flow->init_state, 'input', 'init_state');

    is($flow->get_template, 'signup/index', 'index template');
    
    isa_ok(my $continue = $flow->get_continue, 'Ark::Flow::Continue');

    is($continue->namespace, 'index', 'index namespace');

      like($continue->get_flow_id, qr{ ^.{8}$ }xms, 'flow_id length is 8 char');

    is($continue->get_flow_id, $c->stash->{flow_id}, 'flow_id is set to stash');

    isa_ok(my $state = $flow->get_state_obj, 'Ark::Flow::State');


    # remember $FLOW_ID and $COOKIE
    $FLOW_ID = $c->stash->{flow_id};
    $COOKIE = $c->res->headers->{'set-cookie'}->[0];
}

{
    # input -> confirm
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID" ,
        {
            confirm_submit => 1,
            required_param => 1,
        },
        Cookie => $COOKIE,
    );

    is( $c->req->param('confirm_submit'), 1, 'confirm_submit is 1' );

    is( $c->stash->{flow_id}, $FLOW_ID, 'stash flow_id is same as previous one' );

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );

    is( $flow->get_state_obj->get_state, 'confirm', 'state is confirm' );

    is($flow->get_template, 'signup/confirm', 'template is signup/confirm');

    is( $flow->get_attribute('flow_init'), 1, 'get_attribute');

    is( $flow->get_continue->is_init, 0, 'Ark::Flow::Continue is not initialized ok' );

    is_deep( $flow->get_attribute('test_set_attribute_hash'), { hoge => 'hoge', huga => 'huga', }, 'get_attribute hash');
    
    $FLOW_ID = $c->stash->{flow_id};
}

{
    # confirm -> complete

    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID" ,
        {
            complete_submit => '1',
        },
        Cookie => $COOKIE,
    );

    is( $c->stash->{flow_id}, $FLOW_ID, 'stash flow_id param is same as previous request' );

    my $flow = $c->stash->{flow};

    is( $flow->get_state_obj->get_state, 'complete', 'confirm -> complete, state is complete' );

    is($flow->get_template, 'signup/complete', 'template should be signup/complete');

    is( $flow->get_continue->is_init, 0, 'Ark::Flow::Continue is not initialized' );

    is( $flow->get_attribute('test_set_attribute_hash'), undef, 'attribute test_set_attribute_hash is removed.');
}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=aaa",
        Cookie => $COOKIE,
    );

    isnt( $c->stash->{flow_id}, $FLOW_ID, 'flow_id is changed by request with nonexistent flow_id' );

    my $flow = $c->stash->{flow};

    is( $flow->get_continue->is_init, 1, 'create new Ark::Flow::Continue object' );

    is( $flow->get_state_obj->get_state, $flow->init_state, 'now, state is reset to init_state' );

    is( $flow->get_template, 'signup/index', 'templete should be signup/index' );

    like($flow->get_continue->get_flow_id, qr{  ^.{8}$  }xms, 'regenerate flow_id, length is 8 char');
}




{
    my ($res, $c) = ctx_request(
        POST "/",
        Cookie => $COOKIE,
    );
    
    my $flow = $c->stash->{flow};

    is( $flow->get_state_obj->get_state, $flow->init_state, 'start state is set to init_state' );

    like($flow->get_continue->get_flow_id, qr{  ^.{8}$  }xms, 'regenerate flow_id, length is 8 char');

    $FLOW_ID = $c->stash->{flow_id};
}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID",
        {
            confirm_submit => 1,
            required_param => 0,
        },
        Cookie => $COOKIE,
    );
    
    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );

    is($c->stash->{is_valid}, 0, 'param validation failed');

    is($flow->get_state_obj->get_state, 'input', 'state still input');

    $FLOW_ID = $c->stash->{flow_id};

}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID",
        {
            confirm_submit => 1,
            required_param => 1,
        },
        Cookie => $COOKIE,
    );

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );

    is($c->stash->{is_valid}, 1, 'param validation ok');

    is($flow->get_state_obj->get_state, 'confirm', 'input -> confirm, state changed ok');

    $FLOW_ID = $c->stash->{flow_id};
}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID",
        {
            back_submit => 1,
        },
        Cookie => $COOKIE,
    );

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );

    is($flow->get_state_obj->get_state, 'input', 'confirm -> input, state changed ok');
    
    $FLOW_ID = $c->stash->{flow_id};

}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID",
        {
            confirm_submit => 1,
            required_param => 1,
            save_param     => 'save me!!',
        },
        Cookie => $COOKIE,
    );

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );

    is( $flow->get_state_obj->get_state, 'confirm', 'input -> confirm, state changed ok');

    $FLOW_ID = $c->stash->{flow_id};
}

{
    my ($res, $c) = ctx_request(
        POST "/?flow_id=$FLOW_ID",
        {
            complete_submit_x => 1, # allow submit_name_x and submit_name_y
        },
        Cookie => $COOKIE,
    );

    isa_ok( my $flow = $c->stash->{flow}, 'Ark::Flow' );
    
    is($flow->get_state_obj->get_state, 'complete', 'confirm -> complete, state changed ok');

    is( $c->stash->{values}, 'save me!!', 'set_attribute string' );
    
    is_deep( $c->stash->{test_set_attribute_hash}, { hoge => 'hoge', huga => 'huga', }, 'set_attribute hash' );

    is( $flow->get_attribute( 'values' ), undef, 'attribute "values" is removed in action "complete" T/Controller/Root.pm' );

    is( $flow->get_attribute( 'test_set_attribute_hash' ), undef, 'attribute "test_set_attribute_hash" is removed in action "complete" T/Controller/Root.pm' );

    $FLOW_ID = $c->stash->{flow_id};

    # reset flow_id by request without flow_id param.
    ($res, $c) = ctx_request(
        POST "/",
        Cookie => $COOKIE,
    );

    isnt( $c->stash->{flow_id}, $FLOW_ID, 'flow_id is reset by request without flow_id param ok' );
}
