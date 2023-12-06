use strict;
use warnings;
use Test::More;


use Catalyst::Test 'App::IBIS';
use App::IBIS::Controller::Circos;

ok( request('/circos')->is_success, 'Request should succeed' );
done_testing();
