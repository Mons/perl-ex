#!/usr/bin/perl

use strict;
use ex::lib qw(../lib .);
use Test::More tests => 2;

BEGIN { use_ok 'ex::die' }
BEGIN {
	SIG_DIE {
		ok 1, "die catched";
		exit 0;
	};
}
use InnerBadModule;
