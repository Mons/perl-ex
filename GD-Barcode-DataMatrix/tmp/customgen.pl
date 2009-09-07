#!/usr/bin/perl

use strict;
use lib::abs '../lib';
chdir lib::abs::path '.';
use GD::Barcode::DataMatrix::Engine;

my ($text,$type,$size) = @ARGV;
#system("script/barcode $text $type $size");
#system("cd java;java prog $text $type $size;cd -");

sub E_C40    () { 1 }
sub E_TEXT   () { 2 }
sub E_BASE256() { 3 }
sub E_NONE   () { 4 }

print q{#!/usr/bin/env perl

use strict;
use lib qw(./lib ../lib);
use Test::More 'no_plan';
BEGIN { use_ok('GD::Barcode::DataMatrix') };
sub bar($$$;$){ local $_ = GD::Barcode::DataMatrix->new(  $_[0], Type => $_[1], Size => $_[2], ProcessTilde => $_[3] )->barcode();s{\n$}{};$_ }
};

$| = 1;
#my $enc = 'AUTO';
my @tests;
for my $enc ( 'ASCII' ) {
print "### $enc ###\n\n";
for my $sz ( '144x144' ) {
for my $pt(0,1) {
for my $text (
	'x' x 1600,#1558,
	qw(
	test 123test 111111wer#$R
	AAAAAA aaaaaaa AaAaAaAa ZzZzZzzZZ someData1~#
	!@#$WW
	t~~t
	~1 1~1 11~1 111~1 1111~1 11111~1
	~2111 ~211 ~2111t 2~2111
	~3 1~3
	~4 1~4
	~5 1~5
	~6 1~6
	t~7000001t t~7000200t t~7111111t t~711111
)) {
	my $jv = `cd java;java prog '$text' $enc $sz $pt`;
	for( $jv ) {
		chomp;
		#s{^.+?\n.+?\n}{}s;
		tr{* }{10};
		s{\n}{\\n}sg;
	};
print qq{is_deeply(
	[split //,bar('$text','$enc','$sz',$pt)],
	[split //,"$jv"],
	'bar($text $enc $sz $pt)');
};
	last;
}
}}
print "\n";
}
