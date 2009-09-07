#!/usr/bin/perl

use strict;
use lib::abs '../lib';
chdir lib::abs::path '.';

my ($text,$type,$size) = @ARGV;
#system("script/barcode $text $type $size");
#system("cd java;java prog $text $type $size;cd -");

sub E_C40    () { 1 }
sub E_TEXT   () { 2 }
sub E_BASE256() { 3 }
sub E_NONE   () { 4 }

my $v ='1010101';
	my $x = unpack('h*',pack('b7',$v));
	my $y = unpack('b7',pack('h*',$x));
	print $x,"\n",$v,"\n",$y,"\n";
	print $v eq $y ? 1 : 0,"\n";

__END__

my $enc = 'AUTO';
my @tests;
my $sz = '144x144';
for (qw(
	test 123test 111111wer#$R AAAAAA aaaaaaa AaAaAaAa ZzZzZzzZZ
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
	my $pl = `script/barcode '$_' $enc $sz 1`;
	my $jv = `cd java;java prog '$_' $enc $sz 1`;
	print "$_ ".($pl eq $jv ? 'ok' : 'fail')."\n";
	for( $jv ) {
		chomp;
		s{^.+?\n.+?\n}{}s;
		tr{* }{10};
		s{\n}{}sg;
	};
	$, = ' ';
	my $x = unpack('H*',pack('b*',$jv));
	my $y = unpack('b*',pack('H*',$x));
	print $jv,"\n",$y,"\n";
	print $jv eq $y ? 1 : 0,"\n";
	last;
	push @tests, qq{is( bar('$_','$enc','14x14',1),"$jv", 'bar($_ $enc 14x14 pt)');\n};
}
print @tests;
