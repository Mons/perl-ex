#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;

use Test::More qw(no_plan);
use t::TieStderr;
tie *STDERR,'t::TieStderr';

BEGIN { use_ok('ex::debugging') };

ok( DEBUG, 'is DEBUG' );

our $W = 0; our $WW = '';

local $SIG{__WARN__} = sub { $W = 1; ( $WW = shift ) =~ s/\n//; };

debug+0 => 'undef: %s',undef;
is($W,0,'no warn');
is($WW,'','no string warn');

