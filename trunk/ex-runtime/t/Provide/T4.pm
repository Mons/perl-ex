package Provide::T4;

use strict;
use ex::provide
	+fun => [ 't' ],
	-all => [ qw( a b c ) ];

sub a   { "call a" }
sub b   { "call b" }
sub c() { "call c" }
sub t() { "call t" }

1;
