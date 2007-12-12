#!/usr/bin/perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib '..';
our $p;
BEGIN {
	$p = 'ex::runtime';
	#undef *is;
	use lib 't';
	{
		local *is;
		use_ok($p);
		# Rename is as iss because of a collision
		*iss =  sub ($) { goto &ex::runtime::is };
	}
};

for ( @ex::runtime::EXPORT ) {
	no strict 'refs';
	ok(defined \&{$_} ? 1 : 0,'have sub '.$_);
}

ok!	( one { $_==1 } 3,4,5 ) => 'one 0';
ok+	( one { $_==1 } 1,2,3 ) => 'one 1';
ok!	( one { $_==1 } 1,1,3 ) => 'one 2';

ok+	( none { $_==1 } 3,4,5 ) => 'none 0';
ok!	( none { $_==1 } 1,2,3 ) => 'none 1';
ok!	( none { $_==1 } 1,1,3 ) => 'none 2';

ok!	( any { $_==1 } 3,4,5 ) => 'any 0';
ok+	( any { $_==1 } 1,2,3 ) => 'any 1';
ok+	( any { $_==1 } 1,1,3 ) => 'any 2';

ok!	( all { $_==1 } 3,4,5 ) => 'all 0';
ok!	( all { $_==1 } 1,2,3 ) => 'all 1';
ok+	( all { $_==1 } 1,1,1 ) => 'all 2';

{

ok+	do{ local $_ = 1; iss 1    } => 'is 1';
ok!	do{ local $_ = 1; iss 2    } => 'is 2';
ok+	do{ local $_ = 1; iss "1"  } => 'is 3';
ok!	do{ local $_ = 1; iss "2"  } => 'is 4';
ok+	do{ local $_ = 1; iss "01" } => 'is 5';
ok!	do{ local $_ = 1; iss "02" } => 'is 6';

ok+	do{ local $_ = {test => 1};local $a = $_; iss $a } =>  'is 7';
ok!	do{ local $_ = {test => 1};local $b = {test => 1}; iss $b } => 'is 8';

ok+	do{ local $_ = bless [test => 1],'Pk1';local $a = $_; iss $a } => 'is 9';
ok!	do{ local $_ = bless [test => 1],'Pk1';local $b = bless [test => 1],'Pk1'; iss $b } => 'is A';

}
{
	local $_ = 1;
	ok	(like_num,'like_num ~ 1');
	local $_ = 'x';
	ok	(!like_num,'like_num ! "x"');
	local $_ = 'inf';
	ok	(like_num,'like_num ~ "inf"');
	local $_ = 'NaN';
	ok	(like_num,'like_num ~ "NaN"');

	ok	((like_num  1),    'like_num 1');
	ok	((!like_num 'x'),  'like_num "x"');
	ok	((like_num  'inf'),'like_num "inf"');
	ok	((like_num  'NaN'),'like_num "NaN"');
}

ok!	( even 1) => 'even 1';
ok+	( even 2) => 'even 2';

ok+	( odd 1)  =>'odd 1';
ok!	( odd 2)  =>'odd 2';


is	( do{ min 2..5 },      2  => 'min 2..5'  );
is	( do{ min 1,3,5 },     1  => 'min 1,3,5' );
is	( do{ min 'a'..'z' }, 'a' => 'min a..z'  );

is	( do{ max 2..5 },      5  => 'max 2..5'  );
is	( do{ max 1,3,5 },     5  => 'max 1,3,5' );
is	( do{ max 'a'..'z' }, 'z' => 'max a..z'  );

is_deeply [by(2,qw(a b c d))] => [[qw(a b)],[qw(c d)]] => 'by 2';
is_deeply [by(3,qw(a b c d))] => [[qw(a b c)],[qw(d)]] => 'by 3';

is_deeply [uniq qw(d a b c d)] => [qw(d a b c)]        => 'uniq 1';
is_deeply [uniqs qw(d a b c d)] => [qw(d a b c d)]     => 'uniq 2';
is_deeply [uniqs sort qw(d a b c d)] => [qw(a b c d)]  => 'uniq 3';

is_deeply [cutoff 1,[1,2,3],[4,5,6] ] => [2,5]          => 'cutoff 1';
is_deeply [cutoff 1,[1],[4,5,6] ] => [undef,5]          => 'cutoff 2';
is_deeply [cutoff 1,[1,2,3],[4,5,6],[] ] => [2,5,undef] => 'cutoff 3';
is_deeply [cutoff 3,[1,2,3],[4,5,6],[] ] => [(undef)x3] => 'cutoff 4';

is_deeply [ zip [1,2],[3,4] ]   => [ [1,3],[2,4] ]          => 'zip 1';
my @x = ([1,2],[3,4]);
is_deeply [ zip zip @x ] => [ @x ]                          => 'zip zip';

is_deeply [ zip [1,2],[3,4,5] ] => [ [1,3],[2,4] ]          => 'zip 2';
is_deeply [ zip [1,2,3],[3,4] ] => [ [1,3],[2,4] ]          => 'zip 3';

is_deeply kv2h ([1,2],[3,4]) => {1=>3, 2=>4 }               => 'kv2h';

is_deeply { hash (@{[1,2]},@{[3,4]}) } => {1=>3, 2=>4 }     => 'hash';

is_deeply [ zipw {$a+$b+1} [1,2,3],[4,5,6] ] => [6,8,10]    => 'zipw';
is_deeply [ zipsum  [1,2,3],[4,5,6] ] => [5,7,9]            => 'zipsum';
is_deeply [ zipmult [1,2,3],[4,5,6] ] => [4,10,18]          => 'zipmult';
is_deeply [ zipcat  [1,2,3],[4,5,6] ] => ['14','25','36']   => 'zipcat';

is_deeply [ gather { for (1..5) { take $_ } } ] => [1..5]   => 'gather/take';

my @file;
{
	my $pos = tell DATA;
	seek DATA,0,0;
	@file = <DATA>;
};

is			scalar slurp($0)     => join('',@file)            => 'slurp 1';
is_deeply	[slurp($0)]          => \@file                    => 'slurp 2';
is_deeply	scalar slurp($0,[])  => [map { +chomp;$_ } @file] => 'slurp 3';
is_deeply	[slurp($0,[])]       => [map { +chomp;$_ } @file] => 'slurp 4';

is	do{ local $_ = " \ta \t";trim; $_ }, 'a'                  => 'trim 1';
{
	local $_ = " \ta \t";
	my $n = trim;
	is($_," \ta \t", 'trim 2');
	is($n,"a", 'trim 3');
}
{
	my @a = (' a ',' b ');
	trim @a;
	is_deeply [@a] => ['a','b'] => 'trim 4';
}
{
	my @a = (' a ',' b ');
	my @b = trim @a;
	is_deeply [@b] => ['a','b'], 'trim 5';
	is_deeply [@a] => [' a ',' b '], 'trim 6';
}

{
	ok (XX('ef',$0),'XX(ef,$0)');
	ok ((XX 'ef',$0),'XX ef,$0');
	local $_ = $0;
	ok (XX('ef'),'XX(ef)');
	ok ((XX 'ef'),'XX ef');
}

{
	# List::Util methods. Only try them
	is(( first { +defined } undef,7,2 ),7,'first');
	is(@{[shuffle 1..50]}+0,50,'shuffle');
}

{
	# Scalar::Util methods. Only try them
	# weaken blessed isweak tainted readonly
	SKIP: {
		skip "Temporary not implemented test for weaken",1;
		ok(1,'weaken');
	}
	my $x = bless { y => {} };weaken($x->{y}->{x} = $x);
	ok(is_weak($x->{y}->{x}),'is_weak');
	ok(blessed $x,'blessed');
	ok(!blessed {},'not blessed');
	{
		no strict;
		local *CONST = \ 'test';
		my $z = '';
		ok(readonly $CONST,'readonly 1');
		ok(readonly '','readonly 2');
		ok(!readonly $z,'not readonly');
	}
	SKIP: {
		skip "Don't know how to test tainted",1;
		ok(1,'tainted');
	}
}

TODO:{
	local $TODO = 'sizeof not implemented yet';
	local *sizeof = sub{} unless defined &sizeof;
	is (sizeof({}),4,'sizeof({})');
	is (sizeof(\''),4,'sizeof("")');
	is (sizeof(\'x'),4,'sizeof("x")');
	cmp_ok (sizeof({}),'>',4,'sizeof({})');
	cmp_ok (sizeof(''),'>',4,'sizeof({})');
}


__DATA__
