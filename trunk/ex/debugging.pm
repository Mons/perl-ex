# ex::debugging
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::debugging;

=head1 NAME

ex::debugging - Simple debugging in your code with compile-time constants

=head1 SYNOPSIS

	use ex::debugging DEBUGLEVEL;
	use ex::debugging; # defaults to DEBUGLEVEL 1;
	no ex::debugging;
	
Please, note, this will not work (because of explicit empty list doesn't call C<import>):

	use ex::debugging ();
	no ex::debugging ();

=head1 DESCRIPTION

C<ex::debugging> was designed to replace commonly used C<warn sprintf ... if $DEBUG>
There are two interfaces the same time: functional and OO;

=head2 Functional style

Have some unclear restriction: There MUST be a C<+> or C<-> sign after the debug function.
Otherwise, you'll get syntax error, when debugging will be disabled.

=over 4

=item debug + LEVEL, EXPR, LIST;

=back

Writes message to debug log (default - STDERR).
Message will be created using C<sprintf EXPR,LIST>.
LIST will be remapped, so you'll see the undef as "<undef>" and empty string as "''"
Examples:

	debug+0 => 'my test: %s',$var;
	# Produces to STDERR something like:
	# [main:10:] my test: <undef>

Current default output format is:

	[ PACKAGE, LINE, SUB ] MESSAGE

The sub will be get from stack, untill it differs from __ANON__.
So you'll se (if not called from main::) the first named sub.

=head2 OO style

Uses autocreated function C<d> to access the debugging object.
It defines 5 methods: C<debug>, C<info>, C<log>, C<warn>, C<error> with the levels 2..-2 respective.

	d->debug('my test: %s',$var); # equivalent to debug+2 => 'my test: %s', $var;
	d->warn('something wrong with me'); # equivalent to debug-1 => '...';

Also, methods C<warn> and C<error> will work, even if C<no ex::debugging> in effect.

=head2 Old style

Also this module provides well known constant DEBUG, which will work even at compile time

	warn "Something" if DEBUG;
	# will be threated as C<warn "Something"> when DEBUG in effect
	# and as nothing when DEBUG is not in effect

=cut

use strict;
use Carp qw(carp croak);
{
	my $i;
	sub instance() {
		$i ||= __PACKAGE__->new();
		$i;
	}
}

sub new {
	return bless {},shift;
}

sub __method__ {
	
}

sub debug:method { local $_[0] =  2;goto &__debug__ }
sub info :method { local $_[0] =  1;goto &__debug__ }
sub log  :method { local $_[0] =  0;goto &__debug__ }
sub warn :method { local $_[0] = -1;goto &__debug__ }
sub error:method { local $_[0] = -2;goto &__debug__ }

=rem

our %PREFIX = (
	2  => 'DD',
	1  => 'II',
	0  => 'LL',
	-1 => 'WW',
	-2 => 'EE',
);

=cut

our %PREFIX = (
	2  => '  .',
	1  => '  :',
	0  => ' .:',
	-1 => '  *',
	-2 => '***',
);

sub delivery__($$$$$) {
	my ($pk,$ln,$sub,$lvl,$msg) = @_;
	print STDERR (
		($PREFIX{$lvl}||'   ')."[$pk:$ln:$sub] $msg\n"
	);
}

sub __debug__ {
	my ($lvl,$msg,@args) = @_;
#	my $i = 0;
#	my ($pk,$ln) = ( (caller($i))[0], (caller($i))[2] );
	my ($pk,$ln) = ( (caller(0))[0,2,3] );
	my $i = my $ix = 1;
	my $sub;
	#while ($i==1 or $sub eq '__ANON__') {
	#	print ("Clr: ". (caller($i++))[3] );
	#}
	$sub = (caller($i++))[3] while $i==$ix or substr($sub,length($sub)-8,8) eq '__ANON__';
	$sub =~ s{^\Q$pk\::\E}{};
	local $@;
	$pk =~ s/.*::(\w+)$/$1/o;
	$msg =~ s/[\r?\n]+$//o;
	delivery__($pk,$ln,$sub,$lvl,sprintf($msg,@args));
	#warn sprintf "~[$pk:$ln:$lvl] ".('>'x$lvl)." $msg\n",@args;
}

sub enable {
	my ($clr,$level) = @_;
	no strict 'refs';
	#for (qw(debug DEBUG)) {
	#	croak "package `$cls' already have `$_'" if defined &{$clr.'::'.$_};
	#}
	if ($level) {
		*{$clr.'::DEBUG'} = sub(){1};
		*{$clr.'::debug'} = sub($$;@){
			return if $_[0] and $_[0] > $level;
			goto &__debug__;
		};
		my $i = instance();
		*{$clr.'::d'} = sub(){ $i };
	}else{
		*{$clr.'::DEBUG'} = sub(){0};
		*{$clr.'::debug'} = sub(){0};
		my $i = ex::debugging::empty->new();
		*{$clr.'::d'}     = sub(){$i};
	}
}

sub import {
	my $pkg = shift;
	my $caller = caller;
	my $level;
	if (@_) {
		$level = shift || 0;
	}else{
		$level = 1;
	}
	enable($caller,$level);
}

sub unimport {
	my $pkg = shift;
	my $caller = caller;
	carp "Arguments to `no ".__PACKAGE__."' is ignored" if @_;
	enable($caller,0);
}
package ex::debugging::empty;
BEGIN{ $INC{ join('/',split(/::/,__PACKAGE__)).'.pm'} = __FILE__; }

sub new { bless {},shift }
sub debug:method {}
sub info :method {}
sub log  :method {}
sub warn :method { goto &ex::debugging::warn }
sub error:method { goto &ex::debugging::error }

package ex::debugging::delivery;
BEGIN{ $INC{ join('/',split(/::/,__PACKAGE__)).'.pm'} = __FILE__; }

sub import {
	my $pk = shift;
	my $sub = shift;
	Carp::croak "Need coderef" unless ref $sub eq 'CODE';
	no warnings 'redefine';
	*{$pk.'__'} = $sub;
}

1;
__END__

=head1 EXPORTS

This package implicitly exports to the caller's namespace next subroutines: C<DEBUG>, C<debug>, C<d>

=head1 CAVEATS

=head2 NOT SCOPED

The pragma is a per script, not a per block lexical.  Only the last
C<use ex::debugging> or C<no ex::debugging> matters, and it affects 
B<the whole script>.
The multiple use of this pragma is discouraged.

=head2 REQUIREMENTS OF SIGN

Functional style uses compile-time hack, and when C<no debugging> in effect, function C<debug> replaced with 0;

So the statement C<debug+0 => ...> converts to C<0+0, ...> (May be checked using C<B::Deparse>)

When C<use debugging> is in effect C<debug+0 => ...> converts to C<debug( +0, ... )>

Without a sign B<the syntax is erroneous> when no debugging: C<0 0, ...>

If somebody knows, how to hack this, let me know.

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=cut
