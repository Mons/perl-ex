package ex::require;

use strict;
no warnings 'redefine';

our $old;
our $done;

sub import {
	shift;
	return if $done;
	$old = \&CORE::GLOBAL::require;
	eval { $old->() };
	if ($@ =~ /CORE::GLOBAL::require/) { $old = undef; }

	# install our own -require- handler

	*CORE::GLOBAL::require = sub {
		@_ = @_;
		local $_;
		#use Data::Dumper;warn "require ".Dumper(\@_);
		$_[0] = join '/', split '::',$_[0].'.pm' if index($_[0],':') > -1;
		$_[0] = $_[0].'.pm' if $_[0] =~ /^\w+$/;
		my $file = $_[0];
		#warn "require $file\n" if $file =~ /\w+/;

		# perform what was originally expected
		goto &$old if $old;
		my $return;
		# seems to be a version check
		#if ( $file =~ m{^v?[\d\.]+$} ) {
		#	warn "version check: $file\n";
		#	($return) = eval { CORE::require( $file ) }; # needs num value
		#}

		# no special -require- action needed, already loaded before
		if ( $INC{$file} ) {
			$return = 1;
		}

		# first time -require-
		else {
			($return) = eval { CORE::require($file) };
		}

        # something wrong, cleanup and bail out
		if ($_ = $@) {
			my ($f,$l) = (caller)[1,2];
			s{(?: in require)? at .*? line \d+.\s+\n?}{ at $f line $l.\n}s;
			die "My require: $_";
		}

		# really done now
		return $return;
	};
	$done = 1;
	return;
}

sub unimport {
	shift;
	return unless $done;
	if ($old) {
		*CORE::GLOBAL::require = $old;
		$old = undef;
	}else{
		undef *CORE::GLOBAL::require;
	}
	$done = undef;
	return;
}

1;
