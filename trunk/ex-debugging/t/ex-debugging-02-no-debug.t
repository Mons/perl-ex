#!/usr/bin/perl

use strict;
use warnings;
use ex::lib qw(../lib .);

use Test::More qw(no_plan);
use Test::More::Warn;
use TieStderr;
tie *STDERR,'TieStderr';

no ex::debugging;
ok( !DEBUG, 'isnt DEBUG' );

no_warn {

	debug-100 => 'ok';
	is(<STDERR>,'',"L -100 absent");

	debug-1 => 'ok';
	is(<STDERR>,'',"L -1 absent");

	debug+0 => 'test';
	is(<STDERR>,'',"L 0 absent");

	debug+1 => 'ok';
	is(<STDERR>,'',"L 1 absent");

	debug+2 => 'ok';
	is(<STDERR>,'',"L 2 absent");

	debug+3 => 'ok';
	is(<STDERR>,'',"L 3 absent");

	debug+100 => 'ok';
	is(<STDERR>,'',"L 100 absent");

	d->log('log');
	is(<STDERR>,'',"D log absent");

	d->info('info');
	is(<STDERR>,'',"D info absent");

	d->debug('debug');
	is(<STDERR>,'',"D debug absent");

	d->warn('warn');
	like(<STDERR>,qr/\[main:\d+:\] warn/,"D warn good");

	d->error('error');
	like(<STDERR>,qr/\[main:\d+:\] error/,"D error good");

	sub test1 { shift->(); }; test1(sub { debug+0 => 'test'; });
	is(<STDERR>,'',"L sub absent");

#	warn "shit!";
}
