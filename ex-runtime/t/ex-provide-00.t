#!/usr/bin/perl


use strict;
use warnings;
use ex::lib '../lib';
use Test::More tests => 12;

our $p;
BEGIN {
	$p = 'TestProvide';
	use lib 't';
	use_ok($p,'a','b','c');
	use_ok($p,':func');
	use_ok($p,':auto');
	use_ok($p);
};

ok($p->can('import'), 'can import');
ok($p->can('a'));
ok($p->can('b'));
ok($p->can('c'));
is(a(),'call a');
is(b(),'call b');
is(c,'call c');
is(t,'call t');
