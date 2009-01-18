#!/usr/bin/perl -w

use strict;
use warnings;
use ex::lib qw(../lib .);

use Test::More qw(no_plan);
use Test::More::Warn;
use TieStderr;
tie *STDERR,'TieStderr';

BEGIN { use_ok('ex::debugging') };
ok( DEBUG, 'is DEBUG' );
no_warn { debug+0 => 'undef: %s',undef };
