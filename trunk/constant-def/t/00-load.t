#!/usr/bin/perl

use strict;
use lib::abs '../lib';
use Test::More;

BEGIN {
	my $w = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; 1} and $w = 1;
	plan tests => 2+$w;
	use_ok( 'constant::def' );
	use_ok( 'constant::abs' );
}

diag( "Testing constant::def $constant::def::VERSION, Perl $], $^X" );
