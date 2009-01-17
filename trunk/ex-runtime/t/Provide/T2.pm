package Provide::T2;

use strict;
use ex::provide all => [ qw( a b c t ) ];
#	func    => [qw(a b c)],
#	':auto' => [qw(t)],
#;

sub a   { "call a" }
sub b   { "call b" }
sub c() { "call c" }
sub t() { "call t" }

1;
