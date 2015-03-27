## NAME ##

ex::runtime - A set of most used functions


## SYNOPSIS ##


```
        use ex::runtime; # default - full set
        use ex::runtime qw( ... );
```

## DESCRIPTION ##

`ex::runtime` - It's simple

`TODO`: write description :)

> weaken REF:: Make a weakref. Simply an alias to `Scalar::Util::weaken` (Until we have own XS)
> is\_weak EXPR:: If EXPR is a scalar which is a weak reference the result is true. Simply an alias to `Scalar::Util::isweak`
> like\_num EXPR::  like\_num:: Returns true if perl thinks EXPR is a number. Simply an alias to `Scalar::Util::looks_like_number`
> one BLOCK LIST::  none BLOCK LIST::  any BLOCK LIST::  all BLOCK LIST:: `grep`'s a list using block and then test it's size. Meaning:

```
        one  == 1
        none == 0
        any  >  0
        all  == size
Usage:

        one { $_==1 } 3,4,5 ); # false, have no "1"
        one { $_==1 } 1,2,3 ); # true, have only one "1"
        one { $_==1 } 1,1,3 ); # false, have two "1"
```
> is EXPR:: Checks $_for equality with EXPR Function understands context and use `==` or `eq`_

```
        print "Variable is 1" if is 1;
```
> even EXPR::  even::  odd EXPR::  odd:: Checks the EXPR for even/odd
> max LIST:: Returns the entry in the list with the highest value. If the list is empty then `undef` is returned. Also understand string context

```
    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max 'a'..'z'             # 'z'
```
> min LIST:: Similar to `max` but returns the entry in the list with the lowest value. Usage is the same

```
    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min 'a'..'z'             # 'z'
```
> by SCALAR LIST:: Slices array by N items

```
        by(2,qw(a b c d)) => [a b],[c d];
        by(3,qw(a b c d)) => [a b c],[d];
        
```
> uniq LIST:: Make list unique.

```
        @list = uniq qw(d a b c d);       # => qw(d a b c)
```
> uniqs LIST:: The same as 

&lt;uniq&gt;

, only for sorted, but with low memory cost

```
        @list = uniqs sort qw(d a b c d);  # => qw(a b c d)
        @list = uniqs qw(a b b c c c d e); # => qw(a b c d e)
```
> cutoff N, LIST:: Where N is index and LIST is list of N ARRAYREFs Makes a cutoff from N arrays by index

```
        cutoff 1, [1,2,3,4,5], [5,4,3,2,1]; => [2,4]
```
> zip LIST:: Where LIST is list of ARRAYREFs Makes a list of sets, each set containing elements of all lists occuring at the same position

```
        zip [1,2,3], [5,4,3], ['a','b','c']; => [ [1,5,a], [2,4,b], [3,3,c] ];
```
> zipw BLOCK LIST:: Makes a list. Its elements are calculated from the function and the elements of input lists occuring at the same position (LIST is list of ARRAYREFs)

```
        zipw { $a + $b } [1,2,3], [2,3,4]; => [ 3,5,7 ];
```
> zipsum LIST::  zipmult LIST::  zipcat LIST:: Useful aliases to zipw:

```
        zipsum  => zip { $a + $b }
        zipmult => zip { $a * $b }
        zipcat  => zip { $a . $b }
```
> kv2h KEYS, VALUES:: Convert 2 arrayrefs with keys and values to hashref Arguments are keys and values respective

```
        $hash =  kv2h [1,2], [3, 4]; => { 1=>3,2=>4 }
```
> slurp EXPR::  slurp EXPR, REF::  slurp EXPR, REF, FLAG:: Reads all file content. Usage:

```
        $lines = slurp('file');              # same as open($f,...); local $/; <$f>;
        $lines = slurp('file',undef,'utf8'); # same as open($f,'<:utf8',...); local $/; <$f>;
        $lines = slurp('file',[]);           # save as open($f,...); [ map { chomp } <$f> ];
        @lines = slurp('file');              # same as open($f,...); <$f>;
```
> trim::  trim LIST:: Trim whitespace from string

```
        trim;             # affects $_
        trim @list;       # affects @list
        $n = trim;        # makes a copy of $_
        @n = trim @list;  # makes a copy of @list
```
> say:: Well known to Perl6 lovers ;) Same as print, but with trailing \n;

```
        say "test";        # equivalent to print "test","\n";
        say STDOUT "test"; # equivalent to print STDOUT "test","\n";
```
> gather BLOCK / take EXPR:: Also well known Perl6 feature `gather` calls a given block and collects all data, that `take` takes, and return to requestor Next example:

```
        say gather {
                for (1..5) {
                        take if odd;
                }
        };
```
Is equivalent to:

```
        my @gather;
        for (1..5) {
                push @gather, $_ if $_ % 2
        }
        print @gather,"\n";
```
> XX MODE::  XX MODE, EXPR:: Implements emulation of stackable -X Sample usage:

```
        XX('ef',$0); # same as ( -e $0 and -f $0 )
        XX('ef');    # same as ( -e and -f )
```
> sizeof EXPR:: Returns the "size" of EXPR. For array or array reference - the count of elements For hash or hash reference - the count of keys For string or string reference - the length in bytes not regarding the utf8 settings and flags For nubmer or reference to number - always 1 For undef or reference to undef - undef For glob or globref - undef

```
        my $size = sizeof %hash;
        my $size = sizeof @array;
        my $size = sizeof $string;
        my $size = sizeof $hashref;
        my $size = sizeof %{{ inline => 'hash' }};
```
> mkpath EXPR:: Recursively creates path, given by EXPR

```
        mkpath '/a/b/c' or die "Cant create path: $!"
```


## AUTHOR ##

Mons Anderson <inthrax@gmail.com>