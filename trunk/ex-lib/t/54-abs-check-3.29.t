#!/usr/bin/perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/3.29/Cwd.pm};
	require $lib;
}
( my $exe = $0 ) =~ s{[^/\\]+$}{check-abs.pl};
do $exe or die $@;

