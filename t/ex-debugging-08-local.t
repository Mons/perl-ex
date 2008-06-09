#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(. .. t);
use Test::More qw(no_plan);
use TestDebugging;

use ex::debugging::global+3;
use ex::debugging;

# There now shouldn't be any debug

ok( DEBUG, 'ok DEBUG' );

ok_debug { debug+0, shift } "ok +0";
no_debug { debug+5, shift } "no +5";
{
	my $l = ex::debugging::local( { main => 5 } );
	ok_debug { debug+0, shift } "ok +0";
	ok_debug { debug+5, shift } "ok +5";
	no_debug { debug+7, shift } "no +7";
	no_debug { debug+9, shift } "no +9";
	{
		my $l = ex::debugging::local( { main => 7 } );
		ok_debug { debug+0, shift } "ok +0";
		ok_debug { debug+5, shift } "ok +5";
		ok_debug { debug+7, shift } "ok +7";
		no_debug { debug+9, shift } "no +9";
	}
	ok_debug { debug+0, shift } "ok +0";
	ok_debug { debug+5, shift } "ok +5";
	no_debug { debug+9, shift } "no +9";
}

__END__

{
	package test1;
	use ex::debugging;
	use TestDebugging;
	no_debug { debug+0,  shift } "no +0";
	no_debug { debug+5,  shift } "no +5";
}

{
	package test2;
	use ex::debugging+10;
	use TestDebugging;
	no_debug { debug+0,  shift } "no +0";
	no_debug { debug+5,  shift } "no +5";
}

{
	package test3;
	no ex::debugging;
	use TestDebugging;
	no_debug { debug+0,  shift } "no +0";
	no_debug { debug+5,  shift } "no +5";
}

no_debug { debug+0,  shift } "no +0";
no_debug { debug+5,  shift } "no +5";
