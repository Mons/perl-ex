#!/usr/bin/perl -w

use strict;
BEGIN {
	( my $lib = $0 ) =~ s{[^/\\]+$}{lib/Cwd-3.26.pm};
	require $lib;
}
( my $exe = $0 ) =~ s{[^/\\]+$}{check.pl};
do $exe;

