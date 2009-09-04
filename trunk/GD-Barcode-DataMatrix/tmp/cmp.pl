#!/usr/bin/perl

use strict;
use ex::lib '../lib';

my ($text,$type,$size) = @ARGV;
#system("script/barcode $text $type $size");
#system("cd java;java prog $text $type $size;cd -");

sub E_C40    () { 1 }
sub E_TEXT   () { 2 }
sub E_BASE256() { 3 }
sub E_NONE   () { 4 }

my $enc = 'NONE';
my @tests;
for (qw(
	t~~t
	~1 1~1 11~1 111~1 1111~1 11111~1
	~2111 ~211 ~2111t 2~2111
	~3 1~3
	~4 1~4
	~5 1~5
	~6 1~6
	t~7000001t t~7000200t t~7111111t t~711111
)) {
	my $pl = `script/barcode '$_' $enc 14x14 1`;
	my $jv = `cd java;java prog '$_' $enc 14x14 1`;
	print "$_ ".($pl eq $jv ? 'ok' : 'fail')."\n";
	for( $pl ) {
		chomp;
		s{^.+?\n.+?\n}{}s;
		tr{* }{10};
		s{\n}{\\n}sg;
	};
	push @tests, qq{is( bar('$_','$enc','14x14',1),"$pl", 'bar($_ $enc 14x14 pt)');\n};
}
print @tests;
