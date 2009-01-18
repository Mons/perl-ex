#!/usr/bin/perl -w

use strict;
use ex::lib qw(../lib .);
use Test::More tests => 2;

use ex::warn 'mywarn'; # import static function

ok defined &main::mywarn, 'my static';
ok !defined &CORE::GLOBAL::warn, 'no global';
