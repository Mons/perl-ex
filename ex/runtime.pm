# ex::runtime
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::runtime;

=head1 NAME

ex::runtime - A set of most used functions

=head1 SYNOPSIS

	use ex::runtime; # default - full set
	use ex::runtime qw( ... );

=head1 DESCRIPTION

C<ex::runtime> - It's simple

C<TODO>: write description :)

=over 4

=cut

use 5.8.8;
use strict;
our @FROM_SCALAR;
our @FROM_LIST;
BEGIN {
	@FROM_SCALAR = qw(weaken blessed tainted readonly);
	@FROM_LIST   = qw(first shuffle);
	eval qq{ use Scalar::Util qw(@FROM_SCALAR); 1 } or die $@;
	eval qq{ use List::Util   qw(@FROM_LIST);   1 } or die $@;
}
use Carp qw(carp croak confess);
use IO::Handle;
use ex::provide 
	':all'   => [qw(
		is_weak
		carp croak confess
	
		one none any all
		even odd
		
		is like_num
		
		min max
		
		by uniq uniqs
		cutoff zip zipw zipsum zipmult zipcat kv2h hash
		
		slurp trim
		
		is_array is_hash
		
		gather take
		
		say
		
		XX
		
		sizeof
		
		mkpath
	),
	@FROM_LIST,
	@FROM_SCALAR,
	],
;

# Tests


=item weaken REF

Make a weakref.
Simply an alias to C<Scalar::Util::weaken> (Until we have own XS)

=item is_weak EXPR

If EXPR is a scalar which is a weak reference the result is true.
Simply an alias to C<Scalar::Util::isweak>

=cut

BEGIN {
	*is_weak = \&Scalar::Util::isweak;
}

=item like_num EXPR

=item like_num

Returns true if perl thinks EXPR is a number.
Simply an alias to C<Scalar::Util::looks_like_number>

=cut

sub like_num(;$) { Scalar::Util::looks_like_number(@_ ? $_[0] : $_) }

sub _test(&@) { my $c = shift @_; grep &$c,@_; }

=item one BLOCK LIST

=item none BLOCK LIST

=item any BLOCK LIST

=item all BLOCK LIST

C<grep>'s a list using block and then test it's size.
Meaning:

	one  == 1
	none == 0
	any  >  0
	all  == size
Usage:

	one { $_==1 } 3,4,5 ); # false, have no "1"
	one { $_==1 } 1,2,3 ); # true, have only one "1"
	one { $_==1 } 1,1,3 ); # false, have two "1"

=cut

sub one  (&@) { &_test == 1 ? 1 : 0 }
sub none (&@) { &_test == 0 ? 1 : 0 }
sub any  (&@) { &_test  > 0 ? 1 : 0 }
sub all  (&@) { @_-1 == &_test  ? 1 : 0 }

=item is EXPR

Checks $_ for equality with EXPR
Function understands context and use C<==> or C<eq>

	print "Variable is 1" if is 1;


=cut

sub is ($) {
	Scalar::Util::looks_like_number $_ ? $_ == $_[0] : $_ eq $_[0]
}

=item even EXPR

=item even

=item odd EXPR

=item odd

Checks the EXPR for even/odd

=cut

sub even (;$) { ($_[0] || $_ ) % 2 == 0 ? 1 : 0 }
sub odd  (;$) { ($_[0] || $_ ) % 2 == 1 ? 1 : 0 }

# Functions

=item max LIST

Returns the entry in the list with the highest value.
If the list is empty then C<undef> is returned.
Also understand string context

    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max 'a'..'z'             # 'z'

=item min LIST

Similar to C<max> but returns the entry in the list with the lowest
value. Usage is the same

    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min 'a'..'z'             # 'z'

=cut

sub max (@) { ( sort @_ )[-1] }
sub min (@) { ( sort @_ )[ 0] }

=item by SCALAR LIST

Slices array by N items

	by(2,qw(a b c d)) => [a b],[c d];
	by(3,qw(a b c d)) => [a b c],[d];
	
=cut

sub by($@) {
	map{ [ splice @_,1,$_[0] ] } !($#_%$_[0]) .. $#_/$_[0]
}


=item uniq LIST

Make list unique.

	@list = uniq qw(d a b c d);       # => qw(d a b c)

=item uniqs LIST

The same as <uniq>, only for sorted, but  with low memory cost

	@list = uniqs sort qw(d a b c d);  # => qw(a b c d)
	@list = uniqs qw(a b b c c c d e); # => qw(a b c d e)

=cut
sub uniq (@) {
	my %u;
	grep { !$u{$_}++ } ref $_[0] ? @{$_[0]}: @_;
}

sub uniqs (@) {
	my $z;
	grep { $z eq $_ ? 0 : ($z=$_) } @_
}


=item cutoff N, LIST

Where N is index and LIST is list of N ARRAYREFs
Makes a cutoff from N arrays by index

	cutoff 1, [1,2,3,4,5], [5,4,3,2,1]; => [2,4]

=cut

sub cutoff($@) {
	map { $_->[ $_[ $[ ] ] } @_[(1+$[)..$#_]
}

=item zip LIST

Where LIST is list of ARRAYREFs
Makes a list of sets, each set containing elements of all lists occuring at the same position

	zip [1,2,3], [5,4,3], ['a','b','c']; => [ [1,5,a], [2,4,b], [3,3,c] ];

=cut

sub zip (@) {
	map { [ cutoff($_,@_) ] } $[ .. min(map$#$_,@_)
}

=item zipw BLOCK LIST

Makes a list.
Its elements are calculated from the function and the elements of input lists occuring at the same position
(LIST is list of ARRAYREFs)

	zipw { $a + $b } [1,2,3], [2,3,4]; => [ 3,5,7 ];

=item zipsum LIST

=item zipmult LIST

=item zipcat LIST

Useful aliases to zipw:

	zipsum  => zip { $a + $b }
	zipmult => zip { $a * $b }
	zipcat  => zip { $a . $b }

=cut

sub zipw(&@) {
	my $code = shift @_;
	no strict 'refs';
	my $pk = caller;
	map {
		my $i = $_;
		local ${$pk.'::a'} = $_[ $[ ][ $i ];
		local ${$pk.'::b'};# = $_[$i][ $[ + 1 ];
		for ( $[+1 .. $#_) {
			${$pk.'::b'} = $_[$_][ $i ];
			${$pk.'::a'} = $code->();
		}
		${$pk.'::a'};
	} $[ .. min(map$#$_,@_)
}

sub zipsum(@) { zipw { $a + $b } @_ }
sub zipmult(@){ zipw { $a * $b } @_ }
sub zipcat(@) { zipw { $a . $b } @_ }

=item kv2h KEYS, VALUES

Convert 2 arrayrefs with keys and values to hashref
Arguments are keys and values respective

	$hash =  kv2h [1,2], [3, 4]; => { 1=>3,2=>4 }

=cut

sub kv2h ($$) { +{ map { cutoff($_,@_) } $[..max map$#$_,@_ } }
sub hash (\@\@) { map { cutoff($_,@_) } 0..1 }

sub is_array (;$) {
	my $x = ref ($_[0] || $_);
	$x eq 'ARRAY' ? 1 : 0;
}

sub is_hash(;@) {
	my $x = ref ($_[0] || $_);
	$x eq 'HASH' ? 1 : 0;
}

=item slurp EXPR

=item slurp EXPR, REF

=item slurp EXPR, REF, FLAG

Reads all file content. Usage:

	$lines = slurp('file');              # same as open($f,...); local $/; <$f>;
	$lines = slurp('file',undef,'utf8'); # same as open($f,'<:utf8',...); local $/; <$f>;
	$lines = slurp('file',[]);           # save as open($f,...); [ map { chomp } <$f> ];
	@lines = slurp('file');              # same as open($f,...); <$f>;

=cut

sub slurp($;$$){
	open(my $z,'<'.($_[2] ? $_[2] : ''),$_[0]);
	ref $_[1] eq 'ARRAY'
		? wantarray
			? @{ $_[1] } = map { +chomp;$_ } <$z>
			: do { @{ $_[1] } = map { +chomp;$_ } <$z>;$_[1] }
		: wantarray
			? <$z>
			: do {
				local $/;
				<$z>;
			};
}

=item trim

=item trim LIST

Trim whitespace from string

	trim;             # affects $_
	trim @list;       # affects @list
	$n = trim;        # makes a copy of $_
	@n = trim @list;  # makes a copy of @list

=cut

sub trim (;@) {
	defined wantarray
		? wantarray
			? map { s/^\s+//;s/\s+$//;$_ } @_ ? @{[ @_ ]} : $_
			: do { local $_=$_[0] || $_;s/^\s+//;s/\s+$//;$_ }
		: map { s/^\s+//;s/\s+$//;$_ } @_ ? @_ : $_
}


=item say

Well known to Perl6 lovers ;)
Same as print, but with trailing \n;

	say "test";        # equivalent to print "test","\n";
	say STDOUT "test"; # equivalent to print STDOUT "test","\n";

=item gather BLOCK / take EXPR

Also well known Perl6 feature
C<gather> calls a given block and collects all data, that C<take> takes, and return to requestor
Next example:

	say gather {
		for (1..5) {
			take if odd;
		}
	};

Is equivalent to:

	my @gather;
	for (1..5) {
		push @gather, $_ if $_ % 2
	}
	print @gather,"\n";

=cut

sub say(@) {
	print @_,"\n";
}

*IO::Handle::say = sub {
    shift->print(@_,"\n");
};

{
	no strict 'refs';
	no warnings 'redefine';
	sub take(@);
	sub gather (&) {
		my $clr = caller;
		my $cr = shift;
		my @tmp;
		local *take =
		local *{ $clr . '::take' } = sub (@) { push @tmp, @_ == 0 ? $_ : @_; };
		$cr->();
		wantarray ? @tmp : $tmp[$[];
	}
}


=item XX MODE

=item XX MODE, EXPR

Implements emulation of stackable -X
Sample usage:

	XX('ef',$0); # same as ( -e $0 and -f $0 )
	XX('ef');    # same as ( -e and -f )

=cut

sub XX {
	return eval( '!!(' . join(' and ',map { '-'.$_.(@_==2 ? " \$_[1]" : '')  } split //,$_[0]).')' );
}

=item sizeof EXPR

Returns the "size" of EXPR.
For array or array reference - the count of elements
For hash or hash reference - the count of keys
For string or string reference - the length in bytes not regarding the utf8 settings and flags
For nubmer or reference to number - always 1
For undef or reference to undef - undef
For glob or globref - undef

	my $size = sizeof %hash;
	my $size = sizeof @array;
	my $size = sizeof $string;
	my $size = sizeof $hashref;
	my $size = sizeof %{{ inline => 'hash' }};

=cut

{
	sub sizeof(\[$@%&*]){
		my $var = shift;
		$var = $$var if ref $var eq 'REF';
		for (ref $var) {
			if (0) {}
			elsif (is 'HASH'  ) { return scalar keys %$var }
			elsif (is 'ARRAY' ) { return scalar @$var }
			elsif (is 'SCALAR') {
				if (defined $$var) {
					if (like_num $$var) {
						return 1;
					}
					else{
						use bytes;
						return length($$var);
					}
				}else{
					return undef;
				}
			}
			elsif (is 'GLOB'  ) { return undef }
			elsif (is 'CODE'  ) { return undef }
			else { croak "Wrong type?! WTF: $_" }
		}
	}
}

=item mkpath EXPR

Recursively creates path, given by EXPR

	mkpath '/a/b/c' or die "Cant create path: $!"

=cut

sub mkpath ($) {
	my $path = shift;
	my $rel;
	my $rc = 1;
	my @parts = split '/',$path;
	while ( @parts ) {
		$rel .= ( defined $rel ? '/' : '' ) . shift @parts;
		if ( $rel && ! -d $rel){
			$rc = mkdir $rel or last;
		};
	}
	return $rc;
}

1;

__END__

=back

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=cut

