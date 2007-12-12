#!/usr/bin/perl


use strict;
use warnings;
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

ok($p->isa('Exporter'), 'isa exporter');
ok($p->can('a'));
ok($p->can('b'));
ok($p->can('c'));
is(a(),'call a');
is(b(),'call b');
is(c,'call c');
is(t,'call t');
