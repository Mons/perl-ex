#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. .. t);
use Test::More 'no_plan';

BEGIN { use_ok('Provide::T4',':fun') }

ok(!defined &a,'a');
ok(!defined &b,'b');
ok(!defined &c,'c');
is(t,'call t');

