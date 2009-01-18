#!/usr/bin/perl -w

use strict;
use ex::lib qw(../lib .);
use Test::More tests => 2;

use ex::warn (); # only static function

ok defined &ex::warn, 'static';
ok !defined &CORE::GLOBAL::warn, 'no global';