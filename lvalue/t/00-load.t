#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'lvalue' );
}

diag( "Testing lvalue $lvalue::VERSION, Perl $], $^X" );
