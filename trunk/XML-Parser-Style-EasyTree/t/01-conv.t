#!/use/bin/perl -w

use strict;
use Test::More tests => 12;
use ex::lib '../lib';
use XML::Parser;
use Data::Dumper ();
no warnings 'once';

sub DUMP() { 0 }
sub dd ($) { Data::Dumper->new([$_[0]])->Indent(0)->Terse(1)->Quotekeys(0)->Purity(1)->Dump }

our (%FH,%FA,%TX);
*FH  = \%XML::Parser::Style::EasyTree::FORCE_HASH;
*FA  = \%XML::Parser::Style::EasyTree::FORCE_ARRAY;
*TX  = \%XML::Parser::Style::EasyTree::TEXT;

my $xml1 = q{
	<root at="key">
		<nest>
			first
			<v>a</v>
			mid
			<v at="a">b</v>
			<vv></vv>
			last
		</nest>
	</root>
};

my $xml2 = q{
	<root at="key">
		<nest>
			first &amp; mid &amp; last
		</nest>
	</root>
};

my $xml3 = q{
	<root at="key">
		<nest>
			first &amp; <v>x</v> &amp; last
		</nest>
	</root>
};


our $parser = XML::Parser->new( Style => 'EasyTree' );
our $data;
#my $data;
#$data = $parser->parse(q{<root></root>});
#print Dumper $data;
{
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'default'
	or print dd($data),"\n";
}
{
	is_deeply
		$data = $parser->parse($xml2),
		{root => {'-at' => 'key',nest => 'first & mid & last'}},
		'default'
	or print dd($data),"\n";
}
{
	local $TX{JOIN} = '+';
	is_deeply
		$data = $parser->parse($xml2),
		{root => {'-at' => 'key',nest => 'first & mid & last'}},
		'default'
	or print dd($data),"\n";
}
{
	local $TX{JOIN} = '+';
	is_deeply
		$data = $parser->parse($xml3),
		{root => {'-at' => 'key',nest => { '#text' => 'first &+& last', v => 'x' } }},
		'default'
	or print dd($data),"\n";
}
{
	local $FA{root} = 1;
	is_deeply
		$data = $parser->parse($xml1),
		{root => [{'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}]},
		'force array root',
	or print dd($data),"\n";
}
{
	local $FA{nest} = 1;
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => [{'#text' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}]}},
		'force array nest',
	or print dd($data),"\n";
}
{
	local $FA{''} = 1;
	is_deeply
		$data = $parser->parse($xml1),
		{root => [{'-at' => 'key',nest => [{'#text' => 'firstmidlast',vv => [''],v => ['a',{'-at' => 'a','#text' => 'b'}]}]}]},
		'force array all',
	or print dd($data),"\n";
}
{
	local $FH{vv} = 1;
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => {'#text' => ''},v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'force hash vv',
	or print dd($data),"\n";
}
{
	local $FH{''} = 1;
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'firstmidlast',vv => {'#text' => ''},v => [{ '#text' => 'a'},{'-at' => 'a','#text' => 'b'}]}}},
		'force hash all',
	or print dd($data),"\n";
}
{
	local $TX{ATTR} = '+';
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'+at' => 'key',nest => {'#text' => 'firstmidlast',vv => '',v => ['a',{'+at' => 'a','#text' => 'b'}]}}},
		'attr prefix'
	or print dd($data),"\n";
}
{
	local $TX{NODE} = '';
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => {'' => 'firstmidlast',vv => '',v => ['a',{'-at' => 'a','' => 'b'}]}}},
		'text node'
	or print dd($data),"\n";
}
{
	local $TX{JOIN} = ' ';
	is_deeply
		$data = $parser->parse($xml1),
		{root => {'-at' => 'key',nest => {'#text' => 'first mid last',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}},
		'text join'
	or print dd($data),"\n";
}
exit 0;
