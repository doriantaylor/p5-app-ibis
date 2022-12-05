#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Cwd ();

my $wd = Cwd::getcwd();

chdir('js');

exec(qw(npm run build));

chdir("$wd/../root/asset");

exec(qw(psass -t expanded -o main.css main.scss));

chdir($wd);
