use strict;
use warnings;

use App::IBIS;

my $app = App::IBIS->apply_default_middlewares(App::IBIS->psgi_app);
$app;

