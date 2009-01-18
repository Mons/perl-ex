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
