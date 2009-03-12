#!/usr/bin/perl -w

use strict;
use Test::More tests => 3;
use FindBin;
use Cwd;
use lib "$FindBin::Bin/../lib";

BEGIN {
	use_ok( 'ex::lib','.' );
    {
        local $@;
        eval q{ use ex::lib; };
        like($@,qr/Bad usage/, 'empty usage failed');
    }
    {
        local $@;
        eval q{ use ex::lib '../linux/macosx/windows/dos/path-that-never-exists'; }; # ;)
        ok($@, 'wrong path failed');
    }
}

diag( "Testing ex::lib $ex::lib::VERSION using Cwd $Cwd::VERSION, Perl $], $^X" );
