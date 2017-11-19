use strict;
use warnings;
use Test::More;


use Catalyst::Test 'App::IBIS';
use App::IBIS::Controller::Visualization;

ok( request('/visualization')->is_success, 'Request should succeed' );
done_testing();
