package ex::debugging::global;

use strict;
use ex::runtime;
use ex::debugging ();

our @LOADED = ();

sub import {
	shift;
	croak "Global module can be called only once and it was already called before (at @LOADED[1,2])." if @LOADED;
	@LOADED = caller;
	$ex::debugging::NO_DEBUG = 0;
	my $p = shift;
	if (ref $p eq 'HASH') {
		my ($x,$y) = unzip { m{^\(\?[xism-]{5}:.*\)$} } keys %$p;
		$ex::debugging::GLOBAL{$_} = $p->{$_} for @$x;
		push @ex::debugging::GLOBAL_RE, { re => $_, level => $p->{$_} } for @$y;
	}
	elsif (!@_ or ( !ref $p and like_num $p )) {
		$p ||= 0;
		push @ex::debugging::GLOBAL_RE, { re => qr/.*/, level => int $p };
	}
	return;
}

sub unimport {
	shift;
	croak "Global module can be called only once and it was already called before (at @LOADED[1,2])." if @LOADED;
	@LOADED = caller;
	$ex::debugging::NO_DEBUG = 1;
	return;
}

1;
