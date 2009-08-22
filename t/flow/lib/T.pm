package T;
use Ark;

use_plugins qw/
    Session
    Session::State::Cookie
    Session::Store::Memory    
/;

conf 'Plugin::Session::State::Cookie' => {
    cookie_expires => '+3d',
};



1;

