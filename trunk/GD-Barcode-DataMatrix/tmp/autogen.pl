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

$| = 1;
#my $enc = 'AUTO';
my @tests;
for my $enc ( GD::Barcode::DataMatrix::Engine::Types() ) {
print "### $enc ###\n\n";
for my $sz ( map { $$_[0].'x'.$$_[1] } @GD::Barcode::DataMatrix::Constants::FORMATS ) {
for my $pt(0,1) {
for my $text (qw(
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
		s{^.+?\n.+?\n}{}s;
		tr{* }{10};
		s{\n}{\\n}sg;
	};
	print qq{is( bar('$text','$enc','$sz',$pt),"$jv", 'bar($text $enc $sz $pt)');\n};
}
}}
print "\n";
}
