#!/usr/bin/perl -w

use strict;
use FindBin;
use lib '.',"$FindBin::Bin/../lib";
use Test::More tests => 1;
use ex::lib sub {};

my $chk = shift @INC; # When left bad sub in @INC Test::Builder fails
is(ref $chk, 'CODE', 'code in @INC');

