#!/usr/bin/perl

package r;

package main;

use Carp;
use uni::perl ':dumper';

our %TABLE;
our %PAR; # parent context
our %CFG; # local context config
our $CTX;
our $DEP = 0;
our $SEP = ':';
our $ARG = '*';
our $ARGS = '...';
our %REV;
our %servers;

sub _tune_locations {
	#warn "tune ".dumper \%PAR, \%CFG;
	return unless exists $CFG{locations} and @{$CFG{locations}};
	my @loc;
	my @re;
	my %match;
	for (@{$CFG{locations}}) {
		#warn "tune single ".dumper $_;
		if (exists $_->{pattern}) {
			#warn "re: $_->{pattern}";
			push @re, $_;
		}
		elsif ($_->{flag} eq '=') {
			#warn "full $_->{path}";
			$match{$_->{path}} = $_;
		}
		else {
			#warn "path: $_->{flag} $_->{path}";
			push @loc, $_;
		}
	}
	@loc = sort {
		length ($b->{path}) <=> length($a->{path})
	} @loc;
	#for (@loc) {
	#	warn ">> $_->{path}";
	#}
	delete $CFG{locations};
	$CFG{dispatch} = {
		%match ? (match => \%match) : (),
		@loc ?   (path  => \@loc)   : (),
		@re ?    (re    => \@re)    : (),
	};
}

our %SEEN;
our $PARENT;
our $DEPTH = -1;
sub _resolve_names;
sub _resolve_names {
	my $x = shift;my %args = @_;
	defined $SEEN{$x} and croak "Cyclic reference";
	local $SEEN{$x} = 1;
	local $DEPTH = $DEPTH + 1;
	#warn "resolve @{[ %$x ]}";
	#return unless defined $x->{name};
	unless ($args{top}) {
		# define full name
		if (defined $PARENT and defined $PARENT->{full}) {
			$x->{full} = join ':', $PARENT->{full}, $x->{name};
		} else {
			$x->{full} = $x->{name};
		}
		$x->{iargs} = $PARENT->{iargs} + ( exists $x->{args} ? $x->{args}[0] : 0 );
		if (!length $x->{name} and !exists $REV{''}) {
			exists $REV{''} and die "Ambiguous root location at @{[ (caller $DEPTH+1)[1,2] ]}. already have ".dumper $REV{''} ;
			$REV{''} = $x;
		}
		if (defined $x->{full}) {
			exists $REV{$x->{full}} and die "Ambiguous name $x->{full} ".dumper $REV{$x->{full}};
			warn "remember reverse name '$x->{full}'";
			$REV{$x->{full}} = $x;
		}
		
		if (!exists $PARENT->{norev} and (!exists $x->{pattern} or !defined $x->{pattern})) {
			warn "define reverse for $x->{full} '$x->{path}'";
			$x->{revx} = [
				$PARENT->{revx} ? @{ $PARENT->{revx} } : (),
				length $x->{path} ? ($x->{path}) : (),
					exists $x->{args} ? (
						defined $x->{args}[0]
							? (\undef) x $x->{args}[0]
							: () # ARGS added after resolving nested
					) : ()
			];
			$x->{rev} =
				( length $PARENT->{rev} ? $PARENT->{rev} : '' ).
				( length $x->{path} ? '/'.$x->{path} : '' ) .
				(
					exists $x->{args} ? (
						defined $x->{args}[0]
							? ('/'.$ARG) x $x->{args}[0]
							: '' # ('/'.$ARGS) # ARGS added after resolving nested
					) : ''
				);
				#( ('/'.$ARG) x ( exists $x->{args} ? $x->{args}[0] : 0 ));
		} else {
			warn "no common reverse for $x->{full}";
			if ($x->{reverse}) {
				
			} else {
				$x->{norev} = 1;
			}
		}
	}
	{
		local $PARENT = $x;
		if (exists $x->{dispatch}{match}) {
			for (values %{ $x->{dispatch}{match} }) {
				_resolve_names $_;
			}
		}
		if (exists $x->{dispatch}{path}) {
			for (@{ $x->{dispatch}{path} }) {
				_resolve_names $_;
			}
		}
		if (exists $x->{dispatch}{re}) {
			for (@{ $x->{dispatch}{re} }) {
				_resolve_names $_;
			}
		}
	}
	if (!$args{top}) {
		if ($x->type} eq 'path') {
			$x->{rev} .= '/'.$ARGS if exists $x->{args} and !defined $x->{args}[0];
			push @{ $x->{revx} }, [] if exists $x->{args} and !defined $x->{args}[0];
			my $rev = delete $x->{revx};
			warn "revx = [@$rev]";
			my $i = 0;
			my $multy = exists $x->{args} && !defined $x->{args}[0] ? 1 : 0;
			my $code =
				'#line '.__LINE__.' '.__FILE__."\nsub {
				\@_ < $x->{iargs} and             warn('Need at least $x->{iargs} arguments, have '.(0+\@_).qq{ at \@{[ (caller 1)[1,2] ]}}),return undef;
				\@_ > $x->{iargs} and !$multy and warn('Need equally $x->{iargs} arguments, have '.(0+\@_).qq{ at \@{[ (caller 1)[1,2] ]}}),return undef;
				return [ ". join (',', map { ref $_ ?
					ref $_ eq 'SCALAR' ? '$_['.($i++).']' :
					ref $_ eq 'ARRAY'  ? '@_['.($i++).'..$#_]' :
					die "Bad ref in reverse: $_"
				: "q#$_#" } @$rev ) . " ]
			}";
			#warn $code;
			$x->{reverse} = eval $code;
			warn if $@;
		} else {
			
		}
	}
	return;
};

sub uri_for {
	my $full = shift;
	$full =~ s{^(\Q$SEP\E)+}{};
	my @args = @_;
	if (exists $REV{$full}) {
		my $loc = $REV{$full};
		#return undef if @args < $loc->{iargs};
		#return undef if @args > $loc->{iargs} and !exists $loc->{args} or defined $loc->{args}[0];
		if (defined $loc->{reverse}) {
			my $parts = $loc->{reverse}(@args);
			return undef unless defined $parts;
			return '/'.join '/',@$parts;
		} else {
			warn "Can't generate reverse for '$full'. use 'reverse { ... };' for manual declaration";
		}
	}
	return undef;
}


sub _dclone;
sub _dclone {
	my $x = shift;
	defined $SEEN{$x} and croak "Cyclic reference";
	local $SEEN{$x} = 1;
	my %loc = %$x;
	$loc{dispatch} = { %{$loc{dispatch}} } if exists $loc{dispatch};
	if (exists $loc{dispatch}{match}) {
		$loc{dispatch}{match} = {%{$loc{dispatch}{match}}};
		for (values %{ $loc{dispatch}{match} }) {
			$_ = _dclone $_;
		}
	}
	if (exists $loc{dispatch}{path}) {
		$loc{dispatch}{path} = [@{$loc{dispatch}{path}}];
		for (@{ $loc{dispatch}{path} }) {
			$_ = _dclone $_;
		}
	}
	if (exists $loc{dispatch}{re}) {
		$loc{dispatch}{re} = [@{$loc{dispatch}{re}}];
		for (@{ $loc{dispatch}{re} }) {
			$_ = _dclone $_;
		}
	}
	return \%loc;
}

sub server(&) {
	defined $CTX and croak "Can't run server in context $CTX";
	%TABLE = ();
	%REV = ();
	local $CTX = 'server';
	local *CFG = \%TABLE;
	shift->();
	_tune_locations;
	_resolve_names(\%TABLE, top => 1);
	return \%TABLE;
}

sub location(&) {
	$CTX =~ m{(?:server|location)} or croak "location could be run in context [server|location]";
	my %loc = (
		flag => ' ',
		#path => '',
	);
	{
		local $CTX = 'location';
		local *PAR = \%CFG;
		local *CFG = \%loc;
		local $DEP = $DEP+1;
		$loc{depth} = $DEP;
		shift->();
		if ($CTX eq 'server' and 
			!exists $loc{path}) {
			warn "root location have no path";
			$loc{path} = '';
			$loc{name} //= '';
		}
		elsif (!exists $loc{path}) {
			$loc{path} = '';
		}
		_tune_locations;
	}
	exists $loc{dispatch}
		or $loc{handlers}
		or die "Neither handler not sub-locations at @{[ (caller)[1,2] ]} in context $CTX\n";
	return \%loc if defined wantarray;
	exists $loc{path} or exists $loc{pattern} or die "No path for location at @{[ (caller)[1,2] ]} in context $CTX\n";
	push @{ $CFG{locations} }, bless(\%loc,'location');
}

sub path($) {
	$CTX eq 'location' or croak "path could be run in context [location]";
	my $path = shift;
	if (exists $CFG{path} or $CFG{pattern}) {
		croak "duplicate path definition. already have ".(exists $CFG{pattern} ? "pattern='$CFG{pattern}'" : "path='$CFG{path}'");
	}
	if ( UNIVERSAL::isa($path,"Regexp") ) {
		$CFG{pattern} = $path;
		$CFG{type} = 'regex';
	} else {
		$path =~ s{^/+}{};
		$path =~ s{/+$}{};
		$path =~ s{/+}{/}sg;
		$CFG{path} = $path;
		$CFG{type} = 'path';
		exists $CFG{name} or $CFG{name} = join $SEP, split '/', $path;
	}
	
}
sub name($) {
	$CTX eq 'location' or croak "name could be run in context [location]";
	$CFG{name} = shift;
}
sub internal() {
	$CTX eq 'location' or croak "internal could be run in context [location]";
	$CFG{internal} = 1;
}
sub fullmatch() {
	$CTX eq 'location' or croak "fullmatch could be run in context [location]";
	$CFG{flag} = '=';
	$CFG{fullmatch} = 1;
}
sub noregex() {
	$CTX eq 'location' or croak "noregex could be run in context [location]";
	$CFG{flag} = '^';
	$CFG{noregex} = 1;
}
sub handler(@) {
	$CTX eq 'location' or croak "noregex could be run in context [location]";
	$CFG{handlers}++;
	if (exists $CFG{locations}) {
		push @{ $CFG{later_handlers}}, \@_;
	} else {
		push @{ $CFG{early_handlers}}, \@_;
	}
}
sub handle (&) {
	$CTX eq 'location' or croak "noregex could be run in context [location]";
	handler code => shift;
}

sub tail($) {
	$CTX eq 'location' or croak "tail could be run in context [location]";
	my $loc = shift;
	push @{ $CFG{locations} }, _dclone $loc;
};

sub back(&;$) {
	$CTX eq 'location' or croak "back could be run in context [location]";
	$CFG{reverse} = shift;
}

sub args(;$@) {
	$CTX eq 'location' or croak "args could be run in context [location]";
	my $n = shift;
	if (defined $n) {
		die "can't mix args() with args(N) at @{[ (caller)[1,2] ]}\n" if exists $CFG{args} and !defined $CFG{args}[0];
		$CFG{args}[0] += $n;
		push @{$CFG{args}}, @_;
	} else {
		die "can't mix args() with args(N) at @{[ (caller)[1,2] ]}\n" if exists $CFG{args} and defined $CFG{args}[0];
		$CFG{args}[0] = undef;
	}
}

our $depth = -1;
{
	sub dumpit {
		my $x = shift;
		local $depth = $depth + 1;
		my $pre = "    "x($depth-1);
		for (values %{ $x->{dispatch}{match} }) {
			printf $pre."full=<%s> (%s) =%s\n", $_->{full}, $_->{name}, $_->{path};
			dumpit($_);
		}
		for (@{ $x->{dispatch}{path} }) {
			printf $pre."full=<%s> (%s) */%s\n", $_->{full}, $_->{name}, $_->{path};
			dumpit($_);
		}
		for (@{ $x->{dispatch}{re} }) {
			printf $pre."full=<%s> (%s) ~%s\n", $_->{full}, $_->{name}, $_->{pattern};
			dumpit($_);
		}
	}
}

#warn dumper \%TABLE;
BEGIN {
	*DEBUG_RESOLVE =
		$ENV{DEBUG_RESOLVE} ? sub () { 1 } : sub () { 0 };
}

sub resolve {
	my $x = shift;
	local $depth = $depth + 1;
	my $pre = "    "x($depth);
	my $path = shift;
	my $return;
	my $actions;
	if (@_) {
		$actions = shift;
	} else {
		$return = $actions = [];
	}
	#$path =~ s{/*$}{/};
	$path =~ s{^/+}{};
	$path =~ s{/+}{/}sg;
	#my @path = split /\//,$path;
	#warn "@path";
	warn "$pre search for '$path'" if DEBUG_RESOLVE;
	if (exists $x->{dispatch}{match}{ $path }) {
		warn "$pre full match for '$path'" if DEBUG_RESOLVE;
		my $loc = $x->{dispatch}{match}{ $path };
		push @$actions, [ $loc,$loc->{early_handlers},[] ] if $loc->{early_handlers};
		push @$actions, [ $loc,$loc->{later_handlers},[] ] if $loc->{later_handlers};
		return $loc;
	}
	my $subpath; # path left if use path location (not regexp)
	my $found;
	my @actions;
	SEARCH:{
		for my $loc (@{ $x->{dispatch}{path} }) {
			@actions = ();
			warn "$pre Check '$path' against $loc->{full} | */$loc->{path}/" if DEBUG_RESOLVE;
			my $trunk;
			if (
				substr($path,0,($trunk=1)+length $loc->{path}) eq $loc->{path}.'/'
				or ($trunk=0) == length $loc->{path}
				or $path eq $loc->{path}
			) {
				$subpath = $path;
				substr $subpath,0,$trunk+length $loc->{path},'';
				warn "$pre found location $loc->{full}, left '$subpath'" if DEBUG_RESOLVE;
				my @args;
				my $may_be_endpoint = 0;
				my @path = split /\//,$subpath;
				if ( exists $loc->{args} ) {
					if (!defined $loc->{args}[0]) {
						warn "$pre args*, may be endpoint" if DEBUG_RESOLVE;
						$may_be_endpoint = 1;
						# TODO: check deeply, and if found nothing, rest are args;
					}
					elsif ( $loc->{args}[0] > 0 ) {
						warn "$pre also need $loc->{args}[0] args" if DEBUG_RESOLVE;
						DEBUG_RESOLVE && warn("$pre have no sufficient args"),next if @path < $loc->{args}[0];
						@args = splice @path,0,$loc->{args}[0];
						$subpath = join '/',@path;
						warn "$pre taken [@args] left $subpath" if DEBUG_RESOLVE;
					}
					elsif (!length $subpath) {
						$may_be_endpoint = 1 if $loc->{handlers};
						warn "$pre have no subpath ($may_be_endpoint)" if DEBUG_RESOLVE;
					}
					else {
						warn "$pre not an endpoint candidate, left '$subpath'" if DEBUG_RESOLVE;
					}
				}
				else {
					if (!length $subpath) {
						$may_be_endpoint = 1 if $loc->{handlers};
						warn "$pre have no subpath ($may_be_endpoint)" if DEBUG_RESOLVE;
					}
					else {
						warn "$pre not an endpoint candidate, left '$subpath'" if DEBUG_RESOLVE;
					}
				}
				$may_be_endpoint = 0 if $loc->{internal};
				#if (@path) {
					if (exists $loc->{dispatch}) {
						warn "$pre try to dispatch '$subpath' deeply" if DEBUG_RESOLVE;
						#my @actions = @$actions;
						push @actions, [ $loc,$loc->{early_handlers},\@args ] if $loc->{early_handlers};
						my $deep = resolve($loc,$subpath,\@actions);
						if ($deep) {
							$found = $deep;
							push @actions, [ $loc,$loc->{later_handlers},\@args ] if $loc->{later_handlers};
							#@$actions = @actions;
							warn "$pre found in depth: $deep" if DEBUG_RESOLVE;
							last; # break path loop
						} else {
							if ($may_be_endpoint) {
								$found = $loc;
								@args = @path;
								push @actions, [ $loc,$loc->{later_handlers},\@args ] if $loc->{later_handlers};
								warn "$pre use as an endpoint with args* [@actions]" if DEBUG_RESOLVE;
								#@$actions = @actions;
								last; # break path loop
							} else {
								warn "$pre no action in deep" if DEBUG_RESOLVE;
								next; # bad location
							}
						}
					}
					elsif ($may_be_endpoint) {
						warn "$pre have no subdispatch, but can args*" if DEBUG_RESOLVE;
						$found = $loc;
						@args = @path;
						push @actions, [ $loc,$loc->{early_handlers},\@args ] if $loc->{early_handlers};
						push @actions, [ $loc,$loc->{later_handlers},\@args ] if $loc->{later_handlers};
						last; # break path loop
					}
					else {
						next # bad location
					}
				#} else {
				#	warn "$pre no subpath, endpoint" if DEBUG_RESOLVE;
				#	push @actions, [ $loc,$loc->{early_handlers},\@args ] if $loc->{early_handlers};
				#	push @actions, [ $loc,$loc->{later_handlers},\@args ] if $loc->{later_handlers};
				#	$found = $loc;
				#	last; # break path loop
				#}
				die "Should not be here";
				last;
			}
		}
		warn "$pre after path search have $found [@actions]" if DEBUG_RESOLVE;
		if ($found and $found->{noregex} ) {
			warn "$pre regex search prohibited" if DEBUG_RESOLVE;
			push @$actions, @actions;
		} else {
			for my $loc (@{ $x->{dispatch}{re} }) {
				warn "$pre Check $path against $loc->{pattern}" if DEBUG_RESOLVE;
				if ($path =~ $loc->{pattern}) {
					$found = $loc;@actions = ();
					my @args = map { substr($path,$-[$_],$+[$_]-$-[$_]) } 1..$#-;
					warn "$pre found rx location $loc->{pattern} [@args]" if DEBUG_RESOLVE;
					#push @$actions, @actions;
					push @$actions, [ $loc,$loc->{early_handlers},\@args ] if $loc->{early_handlers};
					push @$actions, [ $loc,$loc->{later_handlers},\@args ] if $loc->{later_handlers};
					last;
				}
			}
			warn "$pre found no regex match" if DEBUG_RESOLVE;
			push @$actions, @actions if $found;
		}
	}
	#warn "$pre after all search have $found->{full} [@actions]" if DEBUG_RESOLVE;
	if ($found) {
		if ($found->{pattern}) {
			warn "$pre found $found->{full} $found->{pattern} [@$actions]" if DEBUG_RESOLVE;
			return $found;
		} else {
			warn "$pre endpoint $found->{full} [@$actions]" if DEBUG_RESOLVE;
			return $found;
		}
	} else {
		return;
	}
}

sub dispatch {
	my $table = shift;
	my $path = shift;
	my @actions;
	my $loc = resolve $table,$path,\@actions;
	if ($loc) {
		warn "found location $loc->{full} for '$path' with ".(0+@actions)." actions" if DEBUG_RESOLVE;
	for (@actions) {
		my ($loc,$handlers,$args) = @$_;
		for my $handler (@$handlers) {
			if ($handler->[0] eq 'code' ){
				$handler->[1]->($loc,@$args);
			} else {
				die "Unknown handler: @$handler";
			}
		}
	}
	} else {
		warn "found no location for '$path'" if DEBUG_RESOLVE;
	}
	return $loc;
}

use Test::More 'no_plan';
my @test;my $simple;my $loc;

if (0) {
$simple = server {
	location { path '/';                   name 'A';       fullmatch; handle { shift;diag "A @_"; push @test, 'A',@_; }; };
	location { path '/';                   name 'B'; args;            handle { shift;diag "B @_"; push @test, 'B',@_; }; };
	location { path '/images';             name 'C'; args; noregex;   handle { shift;diag "C @_"; push @test, 'C',@_; }; };
	location { path qr{\.(gif|jpg|jpeg)$}; name 'D';                  handle { shift;diag "D @_"; push @test, 'D',@_; }; };
};

#warn dumper \%TABLE;
#dumpit \%TABLE;
@test = ();
dispatch $simple,'/';
is_deeply \@test, ['A'],'/ => A' or diag explain \@test;
@test = ();
dispatch $simple,'/doc/doc.html';
is_deeply \@test, ['B','doc','doc.html'],'/doc/doc.html => B';
@test = ();
dispatch $simple,'/images/1.gif';
is_deeply \@test, ['C','1.gif'],'/images/1.gif => C';
@test = ();
dispatch $simple,'/doc/1.gif';
is_deeply \@test, ['D','gif'],'/doc/1.gif => D';
@test = ();

$simple = server {
	location {
		location {                             name 'A';       fullmatch; handle { shift;diag "A @_"; push @test, 'A',@_; }; };
		location {                             name 'B'; args;            handle { shift;diag "B @_"; push @test, 'B',@_; }; };
		location { path '/images';             name 'C'; args; noregex;   handle { shift;diag "C @_"; push @test, 'C',@_; }; };
		location { path qr{\.(gif|jpg|jpeg)$}; name 'D';                  handle { shift;diag "D @_"; push @test, 'D',@_; }; };
	};
};

#warn dumper \%TABLE;
#dumpit \%TABLE;
@test = ();
dispatch $simple,'/';
is_deeply \@test, ['A'],'/ => A' or diag explain \@test;
@test = ();
dispatch $simple,'/doc/doc.html';
is_deeply \@test, ['B','doc','doc.html'],'/doc/doc.html => B';
@test = ();
dispatch $simple,'/images/1.gif';
is_deeply \@test, ['C','1.gif'],'/images/1.gif => C';
@test = ();
dispatch $simple,'/doc/1.gif';
is_deeply \@test, ['D','gif'],'/doc/1.gif => D';
@test = ();


$simple = server {
	my $tail = location {
		name 'V'; internal;
		args 1;
		handle { shift; push @test, 'V',@_ };
		location {
			path 'edit';
			handle { shift; push @test, 'V.edit',@_ };
		};
		location {
			path 'delete';
			handle { shift; push @test, 'V.delete',@_ };
		};
	};
	location {
		path '/test/'; name 'root';
		handle { shift; push @test,'/',@_ };
		location {
			path 'dog';
			handle { shift; push @test, 'dog before',@_ };
			tail $tail;
			handle { shift; push @test, 'dog after',@_ };
		};
		location {
			path 'cat'; internal;
			handle { shift; push @test, 'cat before',@_ };
			tail $tail;
			location { path 'copycat/with/hat'; fullmatch; handle { shift; push @test,'inner full',@_ }};
			handle { shift; push @test, 'cat after',@_ };
		};
	};
	location {
		path qr{^test/dummy/alias/(.*)};
		name 'regex';
		handle { shift; push @test,'re',@_  };
	};
	location {
		path 'test/dummy/alias';
		name 'dummy';
		fullmatch;
		handle { shift; push @test,'=',@_ };
	};
	location {
		args 1;
		handle { shift; push @test,@_ };
		location {
			path 'some';
			args 2;
			handle { shift; push @test,@_ };
			location {
				path 'any';
				args;
				handle { shift; push @test,@_ };
			}
		}
	}
};

@test = ();
$loc = dispatch $simple,'/test/dog';
is_deeply \@test, ['/','dog before','dog after'],'/test/dog' or diag explain \@test;
is $loc->{full}, 'root:dog', 'root:dog';
@test = ();
$loc = dispatch $simple,'/test/dog/1/edit';
is_deeply \@test, ['/','dog before','V',1,'V.edit','dog after'],'/test/dog/edit' or diag explain \@test;
is $loc->{full}, 'root:dog:V:edit', 'root:dog:V:edit';
@test = ();
$loc = dispatch $simple,'/test/cat';
is_deeply \@test, [],'!/test/cat' or diag explain \@test;
is $loc, undef, '!loc /root/cat';
@test = ();
$loc = dispatch $simple,'/test/cat/2/delete';
is_deeply \@test, ['/','cat before','V',2,'V.delete','cat after'],'/test/cat/edit' or diag explain \@test;
is $loc->{full}, 'root:cat:V:delete', 'root:cat:V:delete';

@test = ();
$loc = dispatch $simple,'/test/dummy/alias';
is_deeply \@test, ['='],'/test/dummy/alias' or diag explain \@test;
is $loc->{full}, 'dummy', 'dummy (fullmatch)';

@test = ();
$loc = dispatch $simple,'/test/dummy/alias/';
is_deeply \@test, ['re',''],'/test/dummy/alias/' or diag explain \@test;
is $loc->{full}, 'regex', 'regex';

@test = ();
$loc = dispatch $simple,'/test/dummy/alias/test';
is_deeply \@test, ['re','test'],'/test/dummy/alias/test' or diag explain \@test;
is $loc->{full}, 'regex', 'regex +';

@test = ();
$loc = dispatch $simple,'/test/cat/copycat/with/hat';
is_deeply \@test, ['/','cat before','inner full','cat after'],'/test/cat/copycat/with/hat' or diag explain \@test;
is $loc->{full}, 'root:cat:copycat:with:hat', 'root:cat:copycat:with:hat';

@test = ();
$loc = dispatch $simple,'/test/cat/copycat/with/hat/';
is_deeply \@test, [],'!/test/cat/copycat/with/hat/' or diag explain \@test;
is $loc, undef, '!loc /test/cat/copycat/with/hat/';

@test = ();
$loc = dispatch $simple,'qwe/some/123/456/any';
is_deeply \@test, ['qwe',123,456], 'args ok' or diag explain \@test;
is $loc->{full}, 'some:any', 'some:any';

}

$simple = server {
	location {
		args 1;
		handle { shift; push @test,@_ };
		location {
			path 'some';
			args 2;
			handle { shift; push @test,@_ };
			location {
				path 'any';
				args;
				handle { shift; push @test,@_ };
				location {
					path 'ex';
					args;
					handle { shift; push @test,@_ };
				}
			}
		};
		location {
			name 'rx.every';
			path qr{^/every(?:|/(.*))};
			back { ['every',@_] };
			handle { shift; push @test,@_ };
		}
	}
};

#say dumper $simple;
is uri_for(''                                      ),undef,                'bad uri :';
is uri_for('','arg'                                ),'/arg',               'good : + arg';
is uri_for('','arg','arg'                          ),undef,                'bad : + args 2';
is uri_for('some'                                  ),undef,                'bad uri :some + 0';
is uri_for('some',1                                ),undef,                'bad uri :some + 1';
is uri_for('some',1,2                              ),undef,                'bad uri :some + 2';
is uri_for('some',1,2,3                            ),'/1/some/2/3',        'ok  uri :some + 3';
is uri_for('some',1,2,3,4                          ),undef,                'bad uri :some + 4';
is uri_for('some:any',1,2                          ),undef,                'bad uri :some:any + 2';
is uri_for('some:any',1,2,3                        ),'/1/some/2/3/any',    'ok  uri :some:any + 3';
is uri_for('some:any',1,2,3,4                      ),'/1/some/2/3/any/4',  'ok  uri :some:any + 4';
is uri_for('some:any:ex',1,                        ),undef,                'bad :some:any:ex + 1';
is uri_for('some:any:ex',1,2,                      ),undef,                'bad :some:any:ex + 2';
is uri_for('some:any:ex',1,2,3                     ),'/1/some/2/3/any/ex', 'ok :some:any:ex + 3';
is uri_for('some:any:ex',1,2,3,4,                  ),'/1/some/2/3/any/ex/4', 'ok :some:any:ex + 4';
is uri_for('rx.every',                             ),undef,  ,             'bad :every';
is uri_for('rx.every',1,                           ),'/1/every',           'ok :every + 1';

