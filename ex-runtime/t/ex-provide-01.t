#!/usr/bin/perl

use strict;
use warnings;
use ex::lib qw(../lib .);
use Test::More 'no_plan';

BEGIN { use_ok('Provide::T1') }

is(a(),'call a');
is(b(),'call b');
is(c,'call c');
is(t,'call t');
