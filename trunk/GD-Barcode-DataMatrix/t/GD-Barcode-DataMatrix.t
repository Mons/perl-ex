#!/usr/bin/perl

#use Test::More tests => 1;
use strict;
use lib::abs '../lib';
use Test::More 'no_plan';
#use Devel::SimpleTrace;
BEGIN { use_ok('GD::Barcode::DataMatrix') };
sub bar($$$){ local $_ = GD::Barcode::DataMatrix->new(  $_[0], Type => $_[1], Size => $_[2] )->barcode();s{\n$}{};$_ }

my $b = GD::Barcode::DataMatrix->new(
	'1', Size => '10x10',
);
for my $size (map { $$_[0].'x'.$$_[1] } @{ GD::Barcode::DataMatrix::Constants::FORMATS() } ) {
	warn "$size\n";
	for my $type ( GD::Barcode::DataMatrix::Engine::Types() ) {
		for my $data (qw(1 test someData1~#)) {
			if (my $b = GD::Barcode::DataMatrix->new($data, Type=> $type, Size => $size)) {
				my $bar = $b->barcode;
				$bar = join '\n', split /\r?\n/, $bar;
				print qq{is( bar('$data','$type','$size'),"$bar", 'bar($data $type $size)');\n};
			}else{
				warn $GD::Barcode::DataMatrix::errStr."\n";
			}
		}
	}
	#print "$size\n";
}
exit;
=rem
for (
	[1,10]
	[1,12]
	[1,]
) {};
=cut
#print $b->barcode() if $b;
#print $GD::Barcode::DataMatrix::errStr unless $b;