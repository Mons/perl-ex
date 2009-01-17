package Test::More::Warn;

use strict;
use Test::More ();
use Sub::Uplevel;
use ex::provide ':all' => [qw(warn_is warn_like no_warn)];

sub no_warn (&;$) {
	my $code = shift;
	my $name = shift;
	my $w = 0;
	my $ww = '';
	local $SIG{__WARN__} = sub { $w = 1; ( $ww = shift ) =~ s/\n//; };
	uplevel 2,$code;
	#$code->();
	if ($w) {
		@_ = ( $ww,undef,$name );
		goto &Test::More::is;
	}
	return;
}

sub warn_is (&$;$) {
	my $code = shift;
	my $req = shift;
	my $name = shift;
	my $w = 0;
	my $ww = '';
	local $SIG{__WARN__} = sub { $w = 1; ( $ww = shift ) =~ s/\n//; };
	uplevel 1,$code;
	#$code->();
	@_ = ( $ww,$req,$name );
	goto &Test::More::is;
	return;
}

sub warn_like (&$;$) {
	my $code = shift;
	my $req = shift;
	my $name = shift;
	my $w = 0;
	my $ww = '';
	local $SIG{__WARN__} = sub { $w = 1; ( $ww = shift ) =~ s/\n//; };
	uplevel 1,$code;
	#$code->();
	@_ = ( $ww,$req,$name );
	goto &Test::More::like;
	return;
}

1;