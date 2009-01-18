#!/usr/bin/perl -w

use strict;
use warnings;
use ex::lib qw(../lib .);
use Test::More qw(no_plan);
use TestDebugging;

use ex::debugging::global;
use ex::debugging;

# There now should be: global: 0, local: 0

ok( DEBUG, 'is DEBUG' );

ok_debug { debug+0,  shift } "ok +0";
no_debug { debug+1,  shift } "no +1";

{
	package test1;
	use ex::debugging;
	use TestDebugging;
	ok_debug { debug+0,  shift } "ok +0";
	no_debug { debug+1,  shift } "no +1";
}

{
	package test2;
	use ex::debugging+1;
	use TestDebugging;
	ok_debug { debug+0,  shift } "ok +0";
	ok_debug { debug+1,  shift } "ok +1";
	no_debug { debug+2,  shift } "no +2";
}

{
	package test3;
	no ex::debugging;
	use TestDebugging;
	no_debug { debug+0,  shift } "no +0";
	no_debug { debug+1,  shift } "no +1";
	no_debug { debug+2,  shift } "no +2";
}

ok_debug { debug+0,  shift } "ok +0";
no_debug { debug+1,  shift } "no +1";
