use strict;
use warnings;
use Test::More;


use Catalyst::Test 'App::IBIS';
use App::IBIS::Controller::IBIS;

ok( request('/ibis')->is_success, 'Request should succeed' );
done_testing();
