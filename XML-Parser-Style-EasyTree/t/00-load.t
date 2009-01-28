#!/use/bin/perl -w

use Test::More tests => 1;
use ex::lib '../lib';

BEGIN {
	use_ok( 'XML::Parser::Style::EasyTree' );
}

diag( "Testing XML::Parser::Style::EasyTree $XML::Parser::Style::EasyTree::VERSION, Perl $], $^X" );
