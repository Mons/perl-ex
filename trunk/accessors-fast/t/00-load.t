#!/usr/bin/perl

use utf8;
use strict;
use warnings;
use Carp;
use ex::lib qw(../../lib);

use Test::More qw(no_plan);
use Data::Dumper;
use_ok 'accessors::fast';
use_ok 'accessors::fast::tie';

diag( "Testing accessors::fast $accessors::fast::VERSION, Perl $], $^X" );
