#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs qw(../lib);
use Test::NoWarnings;
use Test::More tests => 0;

use_ok 'GD::Barcode::Datamatrix';

diag( "Testing GD::Barcode::Datamatrix $GD::Barcode::Datamatrix::VERSION, Perl $], $^X" );
