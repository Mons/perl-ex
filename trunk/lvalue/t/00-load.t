#!/usr/bin/perl

use strict;
use ex::lib '../lib';
use Test::More tests => 1;

BEGIN {
	use_ok( 'lvalue' );
}

diag( "Testing lvalue $lvalue::VERSION, Perl $], $^X" );
