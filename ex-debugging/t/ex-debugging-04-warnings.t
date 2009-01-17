#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(. .. t);

use Test::More qw(no_plan);
use Test::More::Warn;
use t::TieStderr;
tie *STDERR,'t::TieStderr';

BEGIN { use_ok('ex::debugging') };
ok( DEBUG, 'is DEBUG' );
no_warn { debug+0 => 'undef: %s',undef };
