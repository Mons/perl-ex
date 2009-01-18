#!/usr/bin/perl

use strict;
use warnings;
use ex::lib qw(../lib .);
use Test::More 'no_plan';

BEGIN { use_ok('Provide::T4',':fun') }

ok(!defined &a,'a');
ok(!defined &b,'b');
ok(!defined &c,'c');
is(t,'call t');

