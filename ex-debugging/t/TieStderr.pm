package TieStderr;

use strict;
use base qw(Tie::Handle);

sub TIEHANDLE {
	my $pkg = shift;
	my $x = '';
	my $y = \$x; #'
	return bless $y,$pkg;
}

sub PRINT {
	my $self = shift;
	$$self .= shift;
}
sub READLINE {
	my $self = shift;
	( my $var = $$self ) =~ s/\n$//;
	$$self='';
	return $var;
}

1;