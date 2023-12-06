use strict;
use warnings;
use Test::More;


use Catalyst::Test 'App::IBIS';
use App::IBIS::Controller::SKOS;

ok( request('/skos')->is_success, 'Request should succeed' );
done_testing();
