#!/use/bin/perl -w

use Test::More tests => 3;
use lib::abs '../lib';

BEGIN {
	use_ok( 'XML::Parser::Style::EasyTree' );
	use_ok( 'XML::Parser::Style::ETree' );
	is($XML::Parser::Style::EasyTree::VERSION, $XML::Parser::Style::ETree::VERSION, 'versions');
}

diag( "Testing XML::Parser::Style::ETree $XML::Parser::Style::ETree::VERSION, Perl $], $^X" );
