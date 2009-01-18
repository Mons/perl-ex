#!/usr/bin/perl -w

use strict;
use warnings;
use ex::lib qw(../lib .);
use Test::More qw(no_plan);
use TestDebugging;

use ex::debugging::global+5;
use ex::debugging;

# There now should be: global: 5, local: 0
# So max active level: 5;

ok( DEBUG, 'is DEBUG' );

ok_debug { debug+0,  shift } "ok +0";
ok_debug { debug+5,  shift } "ok +5";
no_debug { debug+9,  shift } "no +9";

{
	package test1;
	use ex::debugging;
	use TestDebugging;
	ok_debug { debug+0,  shift } "ok +0";
	ok_debug { debug+5,  shift } "ok +5";
	no_debug { debug+9,  shift } "no +9";
}

{
	package test2;
	use ex::debugging+1;
	use TestDebugging;
	ok_debug { debug+0,  shift } "ok +0";
	ok_debug { debug+5,  shift } "ok +5";
	no_debug { debug+9,  shift } "no +9";
}

{
	package test3;
	no ex::debugging;
	use TestDebugging;
	no_debug { debug+0,  shift } "no +0";
	no_debug { debug+1,  shift } "no +1";
	no_debug { debug+2,  shift } "no +2";
}

ok_debug { debug+5,  shift } "ok +5";
no_debug { debug+9,  shift } "no +9";
