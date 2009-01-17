# ex::debugging
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::debugging;

=head1 NAME

ex::debugging - Simple debugging in your code with compile-time constants

=head1 SYNOPSIS

	use ex::debugging +DEBUGLEVEL;
	use ex::debugging -DEBUGLEVEL;
	use ex::debugging; # defaults to DEBUGLEVEL +1;
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
Also there are a definition of C<assert>

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
use ex::runtime;
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
sub assert:method{ local $_[0] =  0;goto &__assert__ }

our %PREFIX = (
	2  => '  .',
	1  => '  :',
	0  => ' .:',
	-1 => '  *',
	-2 => '***',
);
our $NO_DEBUG = 0;
our %LEVEL = ();

our %GLOBAL = ();
our @GLOBAL_RE = ();

our %LOCAL = ();
our @LOCAL_RE = ();
sub delivery__($$$$$;@) {
	my ($pk,$ln,$sub,$lvl,$msg,@args) = @_;
	print STDERR (
		($PREFIX{$lvl}||'   ')
			.sprintf("[%s:%s:%s] ",map{ defined $_ ? $_ : '' }$pk,$ln,$sub)
			.sprintf(defined $msg ? $msg : '',map{ defined $_ ? $_ : '<undef>' } @args)
		."\n"
	);
}

sub __assert__ {
	no warnings qw(uninitialized);
	my ($lvl,$test,$name,@args) = @_;
	return if $test;
	my ($pk,$ln) = ( (caller(0))[0,2,3] );
	my $i = my $ix = 1;
	my $sub;
	$sub = (caller($i++))[3] while $i==$ix or substr($sub,length($sub)-8,8) eq '__ANON__';
	$sub =~ s{^\Q$pk\::\E}{};
	local $@;
	$pk =~ s/.*::(\w+)$/$1/o;
	$name =~ s/[\r?\n]+$//o;
	my $msg = sprintf "Assertion ($name) failed", @args;
	delivery__($pk,$ln,$sub,$lvl,$msg);
	
	
}

sub __debug__ {
	no warnings qw(uninitialized);
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
	delivery__($pk,$ln,$sub,$lvl,$msg,@args);
	#warn sprintf "~[$pk:$ln:$lvl] ".('>'x$lvl)." $msg\n",@args;
}



sub check_level($$) {
	my ($clr,$level) = @_;
	#return 0 if $level and $level >= $LEVEL{$clr};
	#warn ">>> check level for $clr $level <=> G<$GLOBAL{$clr}> L<$LEVEL{$clr}> <<<\n";
	return 0 if $level and $level > current_level($clr);
	return 1;
}
sub current_level($) {
	my $pk = shift;
	# strict local have highest prioroty
	return $LOCAL{$pk} if exists $LOCAL{$pk};
	# select latest match by regexp
	# so if local({ qr/main/ => 10 }), then local({ qr/.*/ => 0 }), level will be 0
	my $loc = ( grep { $pk =~ /$_->{re}/ } @LOCAL_RE )[-1];
	return $loc if defined $loc;
	
	my @ls = (0);
	push @ls, $GLOBAL{$pk} if exists $GLOBAL{$pk};
	push @ls, $_->{level} for grep { $pk =~ /$_->{re}/ } @GLOBAL_RE;
	push @ls, $LEVEL{$pk} if exists $LEVEL{$pk};
	return int ( max( @ls ) );
}

sub enable {
	my ($clr,$level) = @_;
	no strict 'refs';
	#for (qw(debug DEBUG)) {
	#	croak "package `$cls' already have `$_'" if defined &{$clr.'::'.$_};
	#}
	if (!$NO_DEBUG and defined $level) {
		#print STDERR  "Enabling $clr to level: $level\n";
		*{$clr.'::DEBUG'} = sub(){ 1 };
		*{$clr.'::debug'} = sub($$;@){
			check_level($clr,$_[0]) or return;
			goto &__debug__;
		};
		*{$clr.'::assert'} = sub($$;@){
			check_level($clr,$_[0]) or return;
			goto &__assert__;
		};
		my $i = instance();
		*{$clr.'::d'} = sub(){ $i };
	}else{
		#print STDERR "Disabling $clr to level: $level\n";
		*{$clr.'::DEBUG'} = sub(){0};
		*{$clr.'::debug'} = sub(){0};
		*{$clr.'::assert'} = sub(){0};
		my $i = ex::debugging::empty->new();
		*{$clr.'::d'}     = sub(){$i};
	}
}

sub local ($) {
	defined wantarray or croak q{Lexical localization can't be called in void context. use  { local $val = ... } or { my $var = ... }}; #'
	#ref (my $h = shift) eq 'HASH' or croak q{Wrong argument. use ..::local({ Module::Name => +N, qr/Module::.*/ => +X })};
	my $p = shift;
	my ($x,$y) = ([],{});
	if (ref $p eq 'HASH') {
		my $z;
		($x,$z) = unzip { m{^\(\?[xism-]{5}:.*\)$} } keys %$p;
		$y->{$_} = $p->{$_} for @$z;
	}
	elsif (!@_ or ( !ref $p and like_num $p )) {
		my $caller = caller;
		$x = [ $caller => int $p ];
	}
	else{
		croak q{Wrong argument. use ..::local({ Module::Name => +N, qr/Module::.*/ => +X }) or ..::local(+N)};
	}
	my $re = @$x;
	my %h = %$y;
	my @keys = keys %h;
	my %orig = map { $_ => $LOCAL{$_} } grep { exists $LOCAL{$_} } @keys;
	@LOCAL{@keys} = @h{@keys};
	push @LOCAL_RE,@$x;
	# Return cleanup funtion
	return ex::debugging::lex->new(sub {
		delete $LOCAL{$_} for grep { !exists $orig{$_} } @keys;
		$LOCAL{$_} = $orig{$_} for keys %orig;
		pop @LOCAL_RE for 1..$re;
	});
}

{
	my %used;
	sub check_use($) {
		my $p = shift;
		my $type = (caller(1))[3] eq __PACKAGE__.'::import' ? 'use' : 'no';
		if (my $u = $used{$p}) {
			if ($type eq $u->[0]) {
				carp __PACKAGE__ . " was already used (@$u). You shouldn't use it multiple times";
			}
			else {
				croak "Can't $type ". __PACKAGE__ ." because already used (@$u). You mustn't mix `use' and `no'";
			}
			return 0;
		}else{
			$used{$p} = [ $type, sprintf "at %s line %d.",(caller(2))[1,2] ];
			return 1;
		}
	}
}

sub import {
	my $pkg = shift;
	my $caller = caller;
	check_use $caller or return;
	my $level;
	if (@_) {
		$level = shift;
		$LEVEL{$caller} = $level if defined $level;
	}else{
		$level = current_level($caller) || 1;
	}
	enable($caller,$level);
}

sub unimport {
	my $pkg = shift;
	my $caller = caller;
	check_use $caller or return;
	carp "Arguments to `no ".__PACKAGE__."' is ignored" if @_;
	enable($caller,undef);
	@_ = (warnings => "void");
	goto &warnings::unimport;
}

{
	package ex::debugging::empty;
	BEGIN{ $INC{ join('/',split(/::/,__PACKAGE__)).'.pm'} = __FILE__; }
	
	sub new { bless {},shift }
	sub debug:method {}
	sub info :method {}
	sub log  :method {}
	sub warn :method { goto &ex::debugging::warn }
	sub error:method { goto &ex::debugging::error }
}

{
	package ex::debugging::delivery;
	BEGIN{ $INC{ join('/',split(/::/,__PACKAGE__)).'.pm'} = __FILE__; }

	sub import {
		my $pk = shift;
		my $sub = shift;
		Carp::croak "Need coderef" unless ref $sub eq 'CODE';
		no warnings 'redefine';
		*{$pk.'__'} = $sub;
	}
}
{
	# Lexical callback helper
	package ex::debugging::lex;
	use strict;
	sub new {
		my ($pk,$callback) = @_;
		my $self = \$callback;
		return bless $self,$pk;
	}
	sub DESTROY {
		${+shift}->();
	}
}

1;
__END__

=head1 PERFOMANCE

Default routines give very small overhead, much smaller than call to empty subroutine, but the fastest
way with no overhead at all is the old well known if DEBUG. Sad but true

	debug+0 => 'fastest debug' if DEBUG;
	assert+0 => 1==2, 'fastest assert' if DEBUG;
	d->assert(1==2,'fastest assert') if DEBUG;

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

If somebody knows, how to hack this (without source filters ;), let me know.

=head2 COLLISIONS

This package can't be used together with Carp::Assert.

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=cut
