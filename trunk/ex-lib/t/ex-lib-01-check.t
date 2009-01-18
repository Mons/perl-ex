#!/usr/bin/perl -w

use strict;
use FindBin;
use lib '.',"$FindBin::Bin/../lib";
use Test::More tests => 4;

use ex::lib ();
is( $INC[0], ".", "before import: $INC[0]" );
ex::lib->import( '.' );
like( $INC[0], qr{^/}, "after import: $INC[0]" );

SKIP: {
	skip("Cwd required to check correctness", 1)
		unless eval "use Cwd (); 1";
	#is( Cwd::getcwd(), $INC[0], '. => cwd' );
	my $cwd = Cwd::abs_path(__FILE__);
	like( $cwd, qr/^\Q$INC[0]\E/, '. => cwd' );
}

like(ex::lib::mkapath(0), qr{^/}, 'path is absolute');
diag "Need more tests for mkapath";
