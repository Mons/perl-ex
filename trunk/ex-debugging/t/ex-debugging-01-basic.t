#!/usr/bin/perl -w

use strict;
use warnings;
use lib qw(. .. t);
use Test::More qw(no_plan);
use Test::More::Warn;

use t::TieStderr;
tie *STDERR,'t::TieStderr';

BEGIN { use_ok('ex::debugging') };
ok( DEBUG, 'is DEBUG' );

no_warn {

	debug-100 => 'ok';
	like(<STDERR>,qr/\[main:\d+:\] ok/,"L -100 good");

	debug-1 => 'ok';
	like(<STDERR>,qr/\[main:\d+:\] ok/,"L -1 good");

	{
		debug+0 => 'test';my $ln = __LINE__;
		like(<STDERR>,qr/\Q[main:$ln:] test\E/,"L 0 good");
	}

SKIP: {
	skip "Changed behaviour. Default level now 0 instead of 1.", 1;
	debug+1 => 'ok';
	like(<STDERR>,qr/\[main:\d+:\] ok/,"L 1 good");
}

	debug+1 => 'ok';
	is(<STDERR>,'',"L 1 absent");

	debug+2 => 'ok';
	is(<STDERR>,'',"L 2 absent");

	debug+3 => 'ok';
	is(<STDERR>,'',"L 3 absent");

	debug+100 => 'ok';
	is(<STDERR>,'',"L 100 absent");

	d->log('log');
	like(<STDERR>,qr/\[main:\d+:\] log/,"D log good");

	d->info('info');
	like(<STDERR>,qr/\[main:\d+:\] info/,"D info good");

	d->debug('debug');
	like(<STDERR>,qr/\[main:\d+:\] debug/,"D debug good");

	d->warn('warn');
	like(<STDERR>,qr/\[main:\d+:\] warn/,"D warn good");

	d->error('error');
	like(<STDERR>,qr/\[main:\d+:\] error/,"D error good");

	{
		sub test1 { shift->(); }; test1(sub { debug+0 => 'test'; }); my $ln = __LINE__;
		like(<STDERR>,qr/\Q[main:$ln:test1] test\E/,"L 0 good");
	}
	
} 'warnings';
