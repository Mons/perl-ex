#!/usr/bin/perl -w

use strict;
use warnings;
use ex::lib qw(../lib .);
use Test::More qw(no_plan);
use TestDebugging;

no ex::debugging::global;
use ex::debugging;

# There now shouldn't be any debug

ok( !DEBUG, 'no DEBUG' );

no_debug { debug+0,  shift } "no +0";
no_debug { debug+5,  shift } "no +5";

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
