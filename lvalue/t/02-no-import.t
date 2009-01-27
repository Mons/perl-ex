#!/usr/bin/perl -w

use strict;
use ex::lib '../lib';
use Test::More tests => 4;
use lvalue ();

my ($set);
ok !defined &set, '!imported set';
ok !defined &get, '!imported get';

sub both : lvalue {
	lvalue::get {
		'ok';
	}
	lvalue::set {
		$set = shift;
	}
}

is(both, 'ok', 'get');
both = 'set1';
is($set, 'set1', 'set');

