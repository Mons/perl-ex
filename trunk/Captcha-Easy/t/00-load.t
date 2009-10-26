#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 2;

BEGIN {
	use_ok( 'Captcha::Easy' );
	ok Captcha::Easy->new( temp => 't/tmp');
}

diag( "Testing Captcha::Easy $Captcha::Easy::VERSION, Perl $], $^X" );
