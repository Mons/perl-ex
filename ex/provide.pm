# ex::provide
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::provide;

=head1 NAME

ex::provide - Simple replacement of Exporter.

=head1 SYNOPSIS


	use ex::provide METHODS_LIST

	use ex::provide
		':all'      => [ METHODS_LIST ];

	use ex::provide
		':all'      => [ METHODS_LIST ],
		':explicit' => [ METHODS_LIST ];

	use ex::provide all => [ qw(a b c) ];
	use ex::provide qw(a b c);               # the same but simple
	use ex::provide [qw(a b c)];             # the same
	use ex::provide +all => [ qw(a b c) ];   # the same
	use ex::provide ':all' => [ qw(a b c) ]; # the same

	use ex::provide -all => [ qw(a b c) ]; # export only by explicit tag (:all)

=head1 DESCRIPTION

C<ex::provide> makes exporting functions easier.

=over 4

=item :all

The default exporting tag. Always contain all the functions.

=item :*

Functions for specified tag. There is no need to duplicate names in C<:all>

=item -*

Functions for specified tag without autoexport.

=cut


use strict;
no strict 'refs';
use Carp ();

sub exporter {
	my $export = shift;
	return sub {
		my $me  = shift;
		my $pkg = caller;
		my @e = @_ ? @_ : @{ $export->{auto} };
		for (@e) {
			if (s/^://) {
				if ($_ eq 'all') {
					*{$pkg.'::'.$_} = \&{$me.'::'.$_} for keys %{ $export->{all} };
				}else{
					Carp::croak "Package doesn't export tag :$_" unless exists $export->{tags}{$_};
					*{$pkg.'::'.$_} = \&{$me.'::'.$_} for @{ $export->{tags}{$_} };
				}
			}else{
				Carp::croak "Package doesn't export function :$_" unless exists $export->{all}{$_};
				*{$pkg.'::'.$_} = \&{$me.'::'.$_};
			}
		}
		return;
	};
}

sub import {
	shift;
	my $pkg = caller;
	my $args;
	if (grep +ref, @_) {
		if ( @_ > 1 and @_ % 2 == 0 ) {
			$args = [ @_ ];
		}elsif ( @_ == 1 ){
			if (ref $_[0] eq 'HASH' ) {
				$args = [ %{ $_[0] } ];
			}
			elsif (ref $_[0] eq 'ARRAY' ) {
				if (ref $_[0][1]) {
					$args = [ @{ $_[0] } ];
				}else{
					$args = [ all => $_[0] ];
				}
			}
			else {
				Carp::croak "Wrong usage of ". __PACKAGE__;
			}
		}else{
			Carp::croak "Bad usage of " .  __PACKAGE__;
		}
	}else{
		$args = [ all => [ @_ ] ];
	}
	my @exp;
	my @eok;
	my %etg;
	my %all;
	while (@$args) {
		my ($k,$v) = splice(@$args,0,2);
		$k =~ s/^://;
		push @exp, @$v unless $k =~ s/^-//;
		$etg{$k} = $v;
		$all{$_} = 1 for @$v;
		push @eok, @$v;
	}
	*{$pkg.'::import'} = exporter({
		auto   => \@exp,
		demand => \@eok,
		tags   => \%etg,
		all    => \%all,
	});
	return;
}

1;
__END__

=back

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=cut

