#!/usr/bin/perl -w

use strict;
use FindBin;
use overload (); # Test::More uses overload in runtime. With modified INC it may fail
use lib '.',"$FindBin::Bin/../lib";
use Test::More tests => 8;

my @ORIG;
BEGIN { @ORIG = @INC }
our $DIAG = 0;

sub ex () { @INC[0..@INC-@ORIG-1] }

sub diaginc {
	$DIAG or return;
	diag +( @_ ? ($_[0].': ') : ( 'Add INC: ') ) . join ', ', map "'$_'", ex;
}

use ex::lib ();

diaginc();

is( $INC[0], ".", "before import: $INC[0]" );
ex::lib->import( '.' );
diag "Bin = `$FindBin::Bin' ;. is `$INC[0]'";
is( $FindBin::Bin, $INC[0], '. => $FindBin::Bin' );

diaginc();

ex::lib->unimport( '.' );
ok(!ex, 'no ex inc');

diaginc();

# Next tests are derived from lib::tiny


my @dirs = qw(foo bar);
my @adirs = map "$FindBin::Bin/$_",@dirs;
#printf "%o\n", umask(0);
mkdir($_, 0755) or warn "mkdir $_: $!" for @adirs;
chmod 0755, @adirs or warn "chmod $_: $!"; # do chmod (on some versions mkdir with mode ignore mode)

-e $_ or warn "$_ absent" for @adirs;

ex::lib->import(@dirs);

diaginc();
is($INC[0],$adirs[0],'add 0');
is($INC[1],$adirs[1],'add 1');

ex::lib->unimport(@dirs);
diaginc();

ok(!ex, 'dels paths');

eval {
    require lib;
    lib->import(@adirs);
};

SKIP: {
    skip 'apparently too old to handle: Unquoted string "lib" may clash with future reserved word at t/00.load.t line 21.', 1 if $@;
	is($INC[0],$adirs[0],'order same as lib.pm 0');
	is($INC[1],$adirs[1],'order same as lib.pm 1');
};

eval {
    lib->unimport(@adirs);
};

ex::lib->import( '.' );

exit 0;

END{
	rmdir $_ for @adirs; # clean up
}

__END__
diag "Need more tests for mkapath";
		# .
		# ./
		# .//
