#!/usr/bin/env perl

use strict;
use warnings;
use lib::abs '../lib';
use Test::More tests => 4;

use Captcha::Easy;

my $hash;
my $captcha = Captcha::Easy->new( temp => lib::abs::path( 'tmp' ), salt => 'test', debug => 0 );
$hash = $captcha->make( 'test11' );
ok $hash, 'have hash';
ok $captcha->check( 'test11', $hash ), 'firsh check correct';
ok $captcha->check( 'test11', $hash ), 'second check fails';

$hash = $captcha->make( 'test11' );
ok !$captcha->check( 'test12', $hash ), 'wrong check fails';
