#!/usr/bin/perl -w

( my $exe = $0 ) =~ s{[^/\\]+$}{check-abs.pl};
do $exe;
