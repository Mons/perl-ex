package Provide::T5;

use strict;
use ex::provide [ qw( a b c t) ];

sub a   { "call a" }
sub b   { "call b" }
sub c() { "call c" }
sub t() { "call t" }

1;
