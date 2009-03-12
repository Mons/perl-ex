#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;
use FindBin;
use Cwd;
use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok( 'ex::lib' );
}

diag( "Testing ex::lib $ex::lib::VERSION using Cwd $Cwd::VERSION, Perl $], $^X" );
