package TestDebugging;

use strict;
use Sub::Uplevel;
use Test::More();
use Test::More::Warn;
use TieStderr;

use ex::provide
	':all' => [qw(have_debug no_debug ok_debug)];

sub have_debug (&$) {
	my ($c,$n) = @_;
	my $caller = caller;
	my $t = qr/\[$caller:\d+:\] test/;
	tie *STDERR,'TieStderr';
	no_warn {
		uplevel 2,$c,"test";
	} 'warn '.$n;
	my $val = <STDERR>;
	untie *STDERR;
	@_ = ($val,$t,$caller.' '.$n);
	goto &Test::More::like;
}

*ok_debug = \*have_debug;

sub no_debug (&$) {
	my ($c,$n) = @_;
	my $caller = caller;
	tie *STDERR,'TieStderr';
	no_warn {
		uplevel 2,$c,"test";
	} $caller.' warn '.$n;
	my $val = <STDERR>;
	untie *STDERR;
	@_ = ($val,'',$caller.' '.$n);
	goto &Test::More::is;
}

1;
