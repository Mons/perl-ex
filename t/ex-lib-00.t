#!/usr/bin/perl -Tw

use strict;
use Test::More tests => 1;
use lib qw(. .. ./lib ../lib);

BEGIN {
	use_ok( 'ex::lib' );
}

diag( "Testing ex::lib $ex::lib::VERSION, Perl $], $^X" );
