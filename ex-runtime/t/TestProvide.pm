package TestProvide;

use strict;

use ex::provide
	func    => [qw(a b c)],
	':auto' => [qw(t)],
;
	
sub a {
	"call a";
}

sub b {
	"call b";
}

sub c() {
	"call c";
}

sub t() {
	"call t";
}

1;
