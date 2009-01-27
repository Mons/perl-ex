#!/usr/bin/perl -w

use strict;
use FindBin;
use lib '.',"$FindBin::Bin/../lib";
use Test::More tests => 7;

my @ORIG;
BEGIN { @ORIG = @INC }

sub diaginc {
	diag +( @_ ? ($_[0].': ') : ( 'Add INC: ') ) . join ' ', splice  @INC, 0, @INC-@ORIG;
}

use ex::lib ();
is( $INC[0], ".", "before import: $INC[0]" );
ex::lib->import( '.' );
like( $INC[0], qr{^/}, "after import: $INC[0]" );

diaginc();

SKIP: {
	is( $FindBin::Bin, $INC[0], '. => $FindBin::Bin' );
	skip("Cwd.pm required to check cwd", 1)
		unless eval "use Cwd (); 1";
	#is( Cwd::getcwd(), $INC[0], '. => cwd' );
	( my $file = __FILE__ ) =~ s{/[^/]+$}{}s;
	my $cwd = Cwd::abs_path($file);
	like( $cwd, qr/^\Q$INC[0]\E/, '. => cwd' );
}

like(ex::lib::mkapath(0), qr{^/}, 'path is absolute');

# Next tests are derived from lib::tiny

my @dirs = map "$FindBin::Bin/$_",qw(foo bar);
mkdir($_,umask()) or warn "$_: $!" for @dirs; # set up, umask() is for old perl's

ex::lib->import(@dirs);
ok($INC[0] eq $dirs[0] && $INC[1] eq $dirs[1], 'adds paths');

diaginc();

ex::lib->unimport(@dirs);
ok($INC[0] eq $ORIG[0] && $INC[1] eq $ORIG[1], 'dels paths');

eval {
    require lib;
    lib->import(@dirs);
};

SKIP: {
    skip 'apparently too old to handle: Unquoted string "lib" may clash with future reserved word at t/00.load.t line 21.', 1 if $@;
    ok($INC[0] eq $dirs[0] && $INC[1] eq $dirs[1], 'adds paths ordered same as lib.pm');
};

eval {
    lib->unimport(@dirs);
};

END{
	rmdir $_ for @dirs; # clean up
}

diag ". is $INC[0]";
diag "Need more tests for mkapath";
		# .
		# ./
		# .//
