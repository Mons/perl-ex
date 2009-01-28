#!/use/bin/perl -w

use strict;
use dd;
use Test::More tests => 10;
use ex::lib '../lib';
use XML::Parser;
use Data::Dumper;

our (%FH,%FA,$AP,$TNK);
*FH  = \%XML::Parser::Style::EasyTree::FORCE_HASH;
*FA  = \%XML::Parser::Style::EasyTree::FORCE_ARRAY;
$AP  = \$XML::Parser::Style::EasyTree::ATTR_PREFIX;

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

our $parser = XML::Parser->new( Style => 'EasyTree' );
#my $data;
#$data = $parser->parse(q{<root></root>});
#print Dumper $data;
{
	is_deeply
		my $data = $parser->parse($xml1),
		{root => [{'-at' => 'key',nest => {'#text' => 'first mid last',vv => '',v => ['a',{'-at' => 'a','#text' => 'b'}]}}]}
	;
	warn dd $data;
}
{
	local $FH{root} = 1;
	is_deeply
		my $data = $parser->parse($xml1),
		{root => [{nest => [{value => 'a'}],'-attr' => 'key'}]}
	;
	warn dd $data;
}
exit 0;
{
	local $XML::Parser::Style::EasyTree::ATTR_PREFIX = '+';
	is_deeply
		my $data = $parser->parse($xml1),
		{root => [{nest => {value => 'a'},'+attr' => 'key'}]}
	;
	print dd $data;
}
{
#	local $XML::Parser::Style::EasyTree::ATTR_PREFIX = '+';
	is_deeply
		my $data = $parser->parse($xml1),
		{root => [{nest => {value => 'a'},'+attr' => 'key'}]}
	;
	print dd $data;
}
