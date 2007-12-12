# ex::provide
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::provide;

=head1 NAME

ex::provide - Simple replacement of Exporter.

=head1 SYNOPSIS

	use ex::provide
		':all'      => [ METHODS_LIST ];

	use ex::provide
		':all'      => [ METHODS_LIST ],
		':explicit' => [ METHODS_LIST ];

=head1 DESCRIPTION

C<ex::provide> makes exporting functions easier.

=over 4

=item :all

The default exporting functions. Also may be imported by tag C<:all>

=item :*

Functions for specified tag. There is no need to duplicate names in C<:all>

=cut

use strict;
no strict 'refs';
use Exporter;
use Carp ();
our @isa;
our @exp;
our @expo;
our %expt;
sub import {
	shift;
	my $pkg = caller;
	local *isa  = \@{ $pkg . '::ISA' };
	local *exp  = \@{ $pkg . '::EXPORT' };
	local *expo = \@{ $pkg . '::EXPORT_OK' };
	local *expt = \%{ $pkg . '::EXPORT_TAGS' };
	unless ( grep { /^Exporter$/ } @isa ) {
		push @isa,'Exporter';
	}
	my $args;
	if ( @_ > 1 and @_ % 2 == 0 ) {
		$args = [ @_ ];
	}elsif ( @_ == 1 ){
		$args = [ @{ @_[0] } ];
	}else{
		Carp::croak "Bad usage of " .  __PACKAGE__;
	}
	while (@$args) {
		my ($k,$v) = splice(@$args,0,2);
		push @exp,@$v if $k =~ s/^://;
		$expt{$k} = $v;
		push @expo, @$v;
	}
	return;
}

1;
__END__

=back

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=cut

