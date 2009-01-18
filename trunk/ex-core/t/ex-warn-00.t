#!/usr/bin/perl -w

use strict;
use ex::lib qw(../lib .);
use Test::More tests => 1;

BEGIN { use_ok 'ex::warn' }


__END__
BEGIN {
	use Sub::Name;
	#*CORE::GLOBAL::warn = subname 'my::warn' => sub { print STDERR "@_ at @{[ (caller)[1,2] ]}\n"; };
	$,="//";
}
use ex::warn;

print qw(a b c),"\n";
__END__

warn "+".__LINE__.". test: %s","test";
{
	local $ex::warn{+__PACKAGE__};
	warn "-".__LINE__.". test: %s","test";
	ex::warn "+".__LINE__.". test: %s","test";
}
warn "+".__LINE__.". test: %s","test";
ex::warn "+".__LINE__.". test: %s","test";
warn "+".__LINE__.". ", "test","test";
{
	local $ex::warn{+__PACKAGE__};
	warn "-".__LINE__.". ", "test","test";
	ex::warn "+".__LINE__.". ", "test","test";
}
warn "+".__LINE__.". ", "test","test";
ex::warn "+".__LINE__.". ", "test","test";


__END__

warn "test";
warn "test1","test2";
warn "test: %s","test2";

eval { die "die test" };
warn;
undef $@;
eval { die \("die test") };
warn;
undef $@;
$! = "tesT";
open FILE, "<test_file";
$a = <FILE>;
warn "test";

ex::warn "test: %s","test";

#use Data::Dumper;
#print Dumper \%{'::::'};
__END__

package UNIVERSAL;

sub AUTOLOAD {
	return unless substr($AUTOLOAD,0,2) eq '::';
	warn "$AUTOLOAD (@_)\n";
	goto &{ caller().$AUTOLOAD };
	return;
}

package X;
use strict;
use ex::require;
#use ::Test;

package X::Test;

sub new {
	print "new xtest ok\n";
}

package main;

'::Test'->new();

#require '/Test.pm';