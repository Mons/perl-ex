#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. .. t);

use Test::More qw(no_plan);
use Test::More::Warn;
use t::TieStderr;
tie *STDERR,'t::TieStderr';

BEGIN { no_warn{ use_ok('ex::debugging') } };
ok( DEBUG, 'is DEBUG' );

no_warn {

	assert-100 => 1==2, 'ok';
	like(<STDERR>,qr/\[main:\d+:\] Assertion \(ok\) failed/,"L -100 good");

	assert-1 => 1==2, 'ok';
	like(<STDERR>,qr/\[main:\d+:\] Assertion \(ok\) failed/,"L -1 good");

	{
		assert+0 => 1==2, 'test';my $ln = __LINE__;
		like(<STDERR>,qr/\Q[main:$ln:] Assertion (test) failed\E/,"L 0 good");
	}

SKIP: {
	skip "Changed behaviour. Default level now 0 instead of 1.", 1;
	assert+1 => 1==2, 'ok';
	like(<STDERR>,qr/\[main:\d+:\] Assertion \(ok\) failed/,"L 1 good");
}

	assert+1 => 1==2, 'ok';
	is(<STDERR>,'',"L 1 absent");

	assert+2 => 1==2,'ok';
	is(<STDERR>,'',"L 2 absent");

	assert+3 => 1==2, 'ok';
	is(<STDERR>,'',"L 3 absent");

	assert+100 => 1==2, 'ok';
	is(<STDERR>,'',"L 100 absent");

	d->assert(1==2,'log');
	like(<STDERR>,qr/\[main:\d+:\] Assertion .+ failed/,"D log good");

	{
		sub test1 { shift->(); }; test1(sub { assert+0 => 1==2,'test'; }); my $ln = __LINE__;
		like(<STDERR>,qr/\Q[main:$ln:test1] Assertion (test) failed\E/,"L 0 good");
	}

};
