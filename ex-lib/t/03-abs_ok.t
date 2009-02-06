#!/usr/bin/perl -w

use strict;
our (@chk, @inc);
use FindBin;
use overload (); # Test::More uses overload in runtime. With modified INC it may fail
use lib "$FindBin::Bin/../lib";
use Test::More tests => 7;

BEGIN { @inc = @INC }
use ex::lib
	'///opt/perl/lib',
	'//opt/perl/lib',
	'/opt/perl/lib',
	'.///',
	'.//',
	'./',
	'.',
;
BEGIN { @chk = splice @INC, 0 , 0+@INC-@inc } # Don't left anything testing in lib

is($chk[0], '///opt/perl/lib', 'absolute path stay unchanged');
is($chk[1], '//opt/perl/lib',  'absolute path stay unchanged');
is($chk[2], '/opt/perl/lib',   'absolute path stay unchanged');
SKIP: {
    is($chk[3], $FindBin::Bin,     './// => .');
    @chk > 4 or skip "Duplicates are collapsed",3;
    is($chk[4], $FindBin::Bin,     '.// => .');
    is($chk[5], $FindBin::Bin,     './ => .');
    is($chk[6], $FindBin::Bin,     '. => .');
}

exit 0;
