package ex::die;

use strict;

use Carp();
use Sub::Name;

use ex::provide qw(SIG_DIE);

sub ineval_mod_perl {
	local $_ = Carp::longmess();
	s{eval[^\n]+(ModPerl|Apache)/(?:Registry|Dispatch)\w*\.pm.*}{}s
		if exists $ENV{MOD_PERL};
	return /eval [\{\']/m;
}

sub ineval {
	(exists $ENV{MOD_PERL} ? 0 : $^S) || ineval_mod_perl();
}

sub SIG_DIE (&;$) {
	my $caller = caller(0);
	my $handler = shift;
	my $lexical = shift;
	#warn "CALLER = @{[ caller(1) ]}\n";
	subname $caller.'::SIG{__DIE__}' => $handler;
	my $prev = $SIG{__DIE__};
	$SIG{__DIE__} = subname __PACKAGE__ . '::SIG{__DIE__}' => sub {
		#warn "\$SIG{__DIE__}( @_ )\n";
		CORE::die shift,@_ if ineval();
		goto &$handler;
	};
	#printf "wantarray = %s; caller: %s\n",defined wantarray,caller;
	return if !defined wantarray or ( !$lexical and (caller(1))[3] =~ /::BEGIN$/ );
	#warn "register cleanup\n";
	return ex::die::lex->new(sub {
		#warn "Cleaning SIG_DIE\n";
		$SIG{__DIE__} = $prev;
	});
};

package ex::die::lex;
# Lexical callback helper

use strict;

sub new {
	my ($pk,$callback) = @_;
	my $self = \$callback;
	return bless $self,$pk;
}

sub DESTROY {
	${+shift}->();
}

1;
__END__

SYN
use ex::die;

SIG_DIE {
	# catch a die
};
