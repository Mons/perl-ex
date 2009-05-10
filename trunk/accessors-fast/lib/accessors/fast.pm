package accessors::fast;

use strict;
use warnings::register;
use base ();
use constant::def {
    DEBUG   => 0,
    CONFESS => 0,
    TIE     => 0,
};

our $ME;

BEGIN {
	$ME = __PACKAGE__;
	!TIE and eval q{ use Class::Accessor::Fast::XS; 1 }
	     and do{ base->import('Class::Accessor::Fast::XS'); 1 }
	or
	eval { require Class::Accessor::Fast; 1 }
	     and do{ base->import('Class::Accessor::Fast'); 1 }
	or die "accessors::fast can't find neither Class::Accessor::Fast::XS nor Class::Accessor::Fast. ".
	       "Please install one.\n";
	TIE and require accessors::fast::tie;
}

use Hash::Util ();
use Carp ();
use Class::C3 ();

our %CLASS;
our @ADD_FIELDS;

sub mk_accessors {
	my $pkg = shift;
	$pkg = ref $pkg if ref $pkg;
	my %uniq;
	$CLASS{$pkg}{fields} = [ grep !$uniq{$_}++, @{ $CLASS{$pkg}{list} || [] }, @_ ];
	$pkg->next::method(@_);
}

sub field_list {
	my $self = shift;
	my $pkg = ref $self || $self;
	my %uniq;
	$CLASS{$pkg}{isa} ||= do{ no strict 'refs'; \@{$pkg.'::ISA'} };
	#warn "field_list for $self [ @{ $CLASS{$pkg}{fields} || [] } ] +from[ @{ $CLASS{$pkg}{isa} || [] } ]";
	grep !$uniq{$_}++,
		@{ $CLASS{$pkg}{fields} || [] },
		map $_ ne $pkg && $_->can('field_list') ? $_->field_list : (), @{ $CLASS{$pkg}{isa} || [] } ;
}

sub new {
	my $pkg = shift;
	my %h;
	TIE and tie %h, 'accessors::fast::tie', $pkg, [ $pkg->field_list,@ADD_FIELDS ];
	my $self = bless \%h,$pkg;
	&Hash::Util::lock_keys($self,$pkg->field_list,@ADD_FIELDS);
	$self->init(@_);
	return $self;
}

sub init {
	my $self = shift;
	@_ or return;
	my $args;
	{
		my $orig = \@_;
		local $SIG{__WARN__} = sub {
			local $_ = shift;
			m{Odd number of elements}s and Carp::carp ("Wrong init params for $self: [ ".join(', ', map { defined() ? length() ? $_ : "''" : 'undef' } @$orig)." ]. Pass a single hash ref"),return;
			CORE::warn $_;
		};
		$args = ( @_ == 1 && ref $_[0] ) ? shift : +{ @_ };
	}
	#warn "$self\->init (@{[ %$args ]})";
	#warn "$self\->init $args";
	my %chk = map { $_ => 1 } $self->field_list;
	#warn "$self have fields @{[ $self->field_list ]}";
	for (keys %$args) {
		if ($chk{$_}){
			$self->{$_} = $args->{$_};
		}
		elsif(warnings::enabled( $ME )){
			my ($file,$line) = (caller(1))[1,2];
			warn "class `".(ref $self)."' have no field `$_' but instance attempted ".
			     "to be initialized with value '$args->{$_}' at $file line $line.\n";
		}
	}
	return;
}

sub import {
	no strict 'refs';
	( my $me = shift ) eq $ME or return; # Only me can define class isa.
	my $pkg = caller;
	#warn "declare $pkg as $me at @{[ (caller(0))[1,2] ]}";
	push @{$pkg.'::ISA'}, $me unless $pkg->isa($me);
	$CLASS{$pkg}{isa} = \@{$pkg.'::ISA'};
	$pkg->mk_accessors(@_);
}

1;
