#!/usr/bin/perl

use strict;

use Data::Dumper;

use Test::More qw(no_plan);
use t::TieStderr;
tie *STDERR,'t::TieStderr';

BEGIN { ok( eval q{ no ex::debugging;1 }, 'no ex::debugging' ) };


ok		( !DEBUG, 'isnt DEBUG' );

debug-100 => 'ok';
is(<STDERR>,'',"L -100 absent");

debug-1 => 'ok';
is(<STDERR>,'',"L -1 absent");

debug+0 => 'test';my $ln = __LINE__;
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

sub test1 { shift->(); }; test1(sub { debug+0 => 'test'; }); my $ln = __LINE__;
is(<STDERR>,'',"L sub absent");

