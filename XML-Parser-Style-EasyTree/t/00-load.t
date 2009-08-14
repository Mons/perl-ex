#!/use/bin/perl -w

use Test::More tests => 2;
use lib::abs '../lib';

BEGIN {
	use_ok( 'XML::Parser::Style::EasyTree' );
	use_ok( 'XML::Parser::Style::ETree' );
}

diag( "Testing XML::Parser::Style::ETree $XML::Parser::Style::ETree::VERSION, Perl $], $^X" );
