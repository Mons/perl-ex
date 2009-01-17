package Provide::T1;

use strict;
use ex::provide qw( a b c t );
#	func    => [qw(a b c)],
#	':auto' => [qw(t)],
#;

sub a   { "call a" }
sub b   { "call b" }
sub c() { "call c" }
sub t() { "call t" }

1;
