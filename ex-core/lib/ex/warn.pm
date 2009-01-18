package ex::warn;

=head1 FEATURES

1. Make CORE::warn acts as printf.

	# Will be enabled if first argument contains at least one C<%> and number of arguments more than 1
	
	warn "Test: %s", "test" => "Test: test at file line 1."

2. Make CORE::warn to join list of arguments with C<$,>, like C<print> does

	$,= ', ';
	warn "Test1", "Test2" => "Test1, Test2 at file line 1."

3. Provides static sub ex::warn with all this features

	# It may be used without global redefinition of CORE::warn
	
	use ex::warn (); # No import, it redefine the CORE::warn
	
	warn "Test: %s", "test" => "Test: %stest at file line 3."
	warn "Test1", "Test2" => "Test1Test2 at file line 4."
	ex::warn "Test: %s", "test" => "Test: test at file line 5."
	ex::warn "Test1", "Test2" => "Test1, Test2 at file line 6."

=cut

use strict;
no warnings qw(redefine uninitialized);

our $old;
our $done;
our %local; # disable locally
*ex::warn = \%local;
our $core = 0;

sub ex::warn (@) {
	my ($p,$f,$l) = (caller(0))[0..2];
	my $features = !$core || !( exists $local{$p} and !$local{$p} );
	#print STDERR "$p : $local{$p}\n";
	if (
		@_ > 1 and index($_[0],'%') > -1 # have sprintf pattern
		and $features # and not localized
	) {
		@_ = (sprintf(shift,@_));
	}
	$core = 0;
	goto &$old if $old;
	goto &{ $SIG{__WARN__} } if ref $SIG{__WARN__} eq 'CODE';
	local $_;
	if (@_) {
		$_ = join ($features ? $, : '',@_);
	}
	elsif(defined $@) {
		$_ = "$@";
		$_.= "\t...caught at" unless ref $@;
	}
	else {
		$_ = "Warning: Something's wrong";
	}
	local $@;local $SIG{__DIE__};
	# Next statements must be on a single line (they refers to __LINE__)
	eval { CORE::die $_ };$_ = $@;my $me = ' at '.__FILE__.' line '.__LINE__;s{\Q$me\E}{ at $f line $l};
	return CORE::warn( $_ );
}

sub import {
	shift;
	if (@_ == 1) {
		no strict 'refs';
		*{caller().'::'.$_[0]} = \&ex::warn;
		return;
	}
	elsif (@_) {
		die "Unsupported arguments to ex::warn: (@_) at ".join(' line ',(caller)[1,2]).'.';
	}
	return if $done;
	$old = \&CORE::GLOBAL::warn if defined &CORE::GLOBAL::warn and exists &CORE::GLOBAL::warn;

	# install our own warn
	*CORE::GLOBAL::warn = sub { $core = 1; goto &ex::warn };
	$done = 1;
	return;
}

sub unimport {
	shift;
	return unless $done;
	if ($old) {
		*CORE::GLOBAL::warn = $old;
		$old = undef;
	}else{
		undef *CORE::GLOBAL::warn;
	}
	$done = undef;
	return;
}

1;
