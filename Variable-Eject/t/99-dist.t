#!/usr/bin/perl

use Test::More;
use Test::If 'Test::Dist';
use lib::abs '../lib';
chdir lib::abs::path('..');
#BEGIN {
#	$ENV{TEST_AUTHOR} or plan skip_all => '$ENV{TEST_AUTHOR} not set';
#	eval q{ use Test::Dist; 1 } or plan skip_all => 'Test::Dist required';
#	chdir "$FindBin::Bin/.." or plan skip_all => "Can't chdir to dist: $!";
#}

dist_ok(
	skip => [qw(prereq podcover)],
	kwalitee => {
		req => [qw( has_separate_license_file has_example
		metayml_has_provides metayml_declares_perl_version
		has_version_in_each_file
		)],
	},
	prereq => [
		undef,undef, [qw( Test::Pod Test::Pod::Coverage )],
	],
	syntax => {
		file_match => qr{^ex/.+\.(pl|t)$},
	},
);
exit 0;

require Test::Pod::Coverage; # kwalitee hacks, hope temporary
require Test::NoWarnings;
