#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'accessors::fast' );
}

diag( "Testing accessors::fast $accessors::fast::VERSION, Perl $], $^X" );
