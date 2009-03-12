#!/usr/bin/perl

use strict;
use FindBin;
use lib "$FindBin::Bin/..","$FindBin::Bin/../lib";
use Test::More;

my $dist = shift @INC;
eval { require Test::Fixme;Test::Fixme->import() };
plan( skip_all => 'Test::Fixme not installed; skipping' ) if $@;
run_tests(
	where    => $INC[0],
	match    => qr/\b(?:TODO|FIXME)\b/, # what to check for
	skip_all => $ENV{SKIP},
);
