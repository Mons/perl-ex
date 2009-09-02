#!/usr/bin/env perl -w

use strict;
use warnings;
use lib::abs qw(../lib);
use Test::NoWarnings;
use Test::More tests => 2;

use_ok 'GD::Barcode::Datamatrix';
use_ok 'accessors::fast::tie';

diag( "Testing accessors::fast $accessors::fast::VERSION, Perl $], $^X" );
