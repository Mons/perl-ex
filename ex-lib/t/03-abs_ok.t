#!/usr/bin/perl -w

use strict;
use FindBin;
use lib '.',"$FindBin::Bin/../lib";
use Test::More tests => 7;
use ex::lib
	'///opt/perl/lib',
	'//opt/perl/lib',
	'/opt/perl/lib',
	'.///',
	'.//',
	'./',
	'.',
;

my @chk = splice @INC,0, 7; # Don't left anything in lib

is($chk[0], '///opt/perl/lib', 'absolute path stay unchanged');
is($chk[1], '//opt/perl/lib',  'absolute path stay unchanged');
is($chk[2], '/opt/perl/lib',   'absolute path stay unchanged');
is($chk[3], $FindBin::Bin,     './// => .');
is($chk[3], $FindBin::Bin,     '.// => .');
is($chk[3], $FindBin::Bin,     './ => .');
is($chk[3], $FindBin::Bin,     '. => .');

exit 0;
