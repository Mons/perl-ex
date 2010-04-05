#!/usr/bin/perl

package r;

package main;

use Carp;
use uni::perl ':dumper';
no feature 'switch'; # default
use subs qw(listen);
use Data::Dumper;
use AnyEvent;
use AnyEvent::HTTPD;

our %CFG; # global config
our $CFG; # local context config
our $SRV;
our $LOC;
our $CTX;
our %servers;

sub handle {
	my $srv = shift;
	my $r = shift;
	my ($shost,$sport) = ($srv->host, $srv->port);
	{
		local $r->{httpd} = "$r->{httpd}";
		warn "Got request on $shost:$sport $r->{hdr}{host} $r->{url}";
	}
	if (exists $servers{$shost} and exists $servers{$shost}{$sport}) {
		my $s = $servers{$shost}{$sport};
		local $s->{httpd};
		#warn Dumper $s;
		my $host = lc $r->headers->{host};
		$host =~ s{:\d+$}{} if $host;
		my $server;
		if (exists $s->{names}{$host}) {
			$server = $s->{names}{$host};
			warn "Found server $server->{name}{info} by name eq";
		}
		else {
			for (@{ $s->{patterns} }) {
				if ($host =~ $_->[0]) {
					$server = $_->[1];
					warn "Found server $server->{name}{info} by pattern $_->[0]";
					last;
				}
			}
			unless ($server) {
				$server = $s->{default};
				warn "Using default server $server->{name}{info}";
			}
		}
		#warn Dumper $server;
		handle_server($r,$server);
	} else {
		$r->respond([500,'No such server',{ 'content-type' => 'text/plain' }, 'No such server' ]);
	}
	#warn "Got request ".Dumper [ $r->url, $r->params ];
	#my $
}
sub handle_server {
	my ($r,$server) = @_;
	my $uri = $r->{url};
	my $path = $r->url;
	warn "Handling request $uri | $path";
	if (exists $server->{locations}) {
		warn "Server have locations";
		if (exists $server->{locations}{match}{$path}) {
			warn "Found full match location";
			$server->{locations}{match}{$path}->();
		}
		else {
			my $handled;
			my $found;
			for my $loc (@{ $server->{locations}{path} } ) {
				warn "Check $path against $loc->[0]";
				if (substr($path,0,length $loc->[0]) eq $loc->[0]) {
					warn "found location @$loc";
					$found = $loc;
					last;
				}
			}
			my $regex;
			if ($found->[1] eq '^') {
				warn "Don't need to check regex";
				handle_location($r,$found,$server);
				$handled = 1;
			} else {
				for my $loc ( @{ $server->{locations}{re} } ) {
					warn "Check $path against $loc->[0]";
					if ($path =~ $loc->[0]) {
						warn "found rx location @$loc [$1]";
						handle_location($r,$loc,$server);
						$handled = 1;
						last;
					}
				}
			}
			if (!$handled and $found) {
				warn "Handle path location @$found";
				handle_location($r,$found,$server);
				$handled = 1;
			}
			
			unless ($handled) {
				warn "Unhandled path $path";
				$r->respond([404,'Not Found',{ 'content-type' => 'text/plain' }, 'Not Found' ]);
			}
		}
	}
	elsif (exists $server->{root}) {
		warn "Server have no locations but have root $server->{root}";
		
	}
	else {
		warn "Server have neither locations nor root";
	}
	$r->respond([500,'Server found',{ 'content-type' => 'text/plain' }, 'Server found' ])
		unless $r->responded;
}

our $r;

sub handle_location {
	my ($rq,$loc,$server) = @_;
	local $r = $rq;
	local $CTX = 'location';
	my $conf = {};
	local $CFG = $conf;
	my $rc = $loc->[2]->();
	if ($rc =~ /^\d+$/) {
		$r->respond([$rc,'XXX',{ 'content-type' => 'text/plain' }, 'Return: '.$rc ]);
	} else {
		my $root = $conf->{root} // $server->{root};
		warn "No response code; serve $root ";#.dumper $conf,$server;
		serve_static($r,$loc,$server,$conf);
		return;
	}
}
use Sys::Sendfile;
sub serve_static {
	my ($r,$loc,$server,$conf) = @_;
	my $file;
	if ($conf->{alias}) {
		
	}
	elsif ($conf->{root}) {
		$file = $conf->{root}.$r->url;
	}
	warn "send file $file";
	sendfile 
}

sub http (&) {
	my $code = shift;
	local $CTX = 'http';
	local $CFG = \%CFG;
	$code->();
	#warn Dumper \%CFG;
	for my $srv (@{ $CFG{servers} }) {
		for my $addr (keys %{$srv->{listen}}) {
			for my $port (keys %{$srv->{listen}{$addr}}) {
				my %listen = %{$srv->{listen}{$addr}{$port}};
				warn "$addr:$port @{[ %listen ]}\n";
				my $default = delete $listen{default};
				$servers{$addr}{$port} ||= {};
				my @names;
				for ( keys %{ $srv->{name}{names} }) {
					warn "\t$_";
					$servers{$addr}{$port}{names}{$_} = $srv;
					push @names, $_;
				}
				for ( @{ $srv->{name}{patterns} } ) {
					warn "\t$_";
					push @{$servers{$addr}{$port}{patterns}}, [ $_, $srv ];
					push @names, $_;
				}
				if ($default) {
					if (exists $servers{$addr}{$port}{default}) {
						warn "@names can't be default, because default already set";
					}
					$servers{$addr}{$port}{default} = $srv;
				}
				delete $srv->{listen};
				for (keys %listen) {
					if (exists $servers{$addr}{$port}{$_} and $servers{$addr}{$port}{$_} ne $listen{$_}) {
						warn "option $_=$listen{$_} override previous declaration";
					}
					$servers{$addr}{$port}{$_} = $listen{$_};
				}
			}
		}
	}
	#warn Dumper \%servers;
	for my $addr (keys %servers) {
		for my $port (keys %{$servers{$addr}}) {
			my $s = $servers{$addr}{$port}{httpd} = 
				AnyEvent::HTTPD->new(
					host => $addr,
					port => $port,
					backlog => $servers{$addr}{$port}{backlog},
				);
			$s->reg_cb(
				'' => \&handle,
			);
			$s->run;
		}
	}
	AE::cv->recv;
}

our $DEFAULT_BACKLOG = our $BACKLOG = 1024;
sub backlog ():lvalue { $BACKLOG }

sub server (&) {
	push @{$CFG{servers}}, {};
	$CTX eq 'http' or croak "server could be run in context http";
	local $CTX = 'server';
	local $BACKLOG = $DEFAULT_BACKLOG;
	local $CFG = $CFG{servers}[-1];
	shift->();
	my @loc;
	my @re;
	my %match;
	for (@{$CFG->{locations}}) {
		if (exists $_->{pattern}) {
			warn "re: $_->{pattern}";
			push @re, [$_->{pattern},'',$_->{code}];
		}
		elsif ($_->{flag} eq '=') {
			$match{$_->{path}} = $_->{code};
		}
		else {
			warn "path: $_->{flag} $_->{path}";
			push @loc, [ @$_{qw(path flag code)} ];
		}
	}
	@loc = sort {
		length ($b->[0]) <=> length($a->[0])
	} @loc;
	for (@loc) {
		warn ">> @$_";
	}
	$CFG->{locations} = {
		match => \%match,
		path => \@loc,
		re => \@re,
	};
	
}

use constant default => 'default';
#sub default () { 'default' }
=for rem
#syntax:
	listen адрес:порт
		[default|default_server|
		[backlog=число | rcvbuf=размер | sndbuf=размер |
			accept_filter=фильтр | deferred | bind | ipv6only=[on|off] | ssl]]
	default: listen *:80 | *:8000
#context: server
=cut
sub listen (@) {
	$CTX eq 'server' or croak "listen could be run in context server";
	my $addr_port = shift;
	$addr_port =~ s{^(?:\*:|)(\d+)$}{0.0.0.0:$1};
	my ($addr,$port) = split /:/,$addr_port;
	my $l = $CFG->{listen}{$addr}{$port} = {};
	while (@_) {
		local $_ = shift;
		#if (/(.+)=(.+)/)
		if ($_ eq 'default') {
			$l->{default} = 1;
		}
	}
	$l->{backlog} = backlog;
	$BACKLOG = $DEFAULT_BACKLOG;
}

sub server_name (@) {
	$CTX eq 'server' or croak "listen could be run in context server";
	my @names;
	while (@_) {
		local $_ = shift;
		push @names, $_;
		if (UNIVERSAL::isa($_,"Regexp")) {
			push @{$CFG->{name}{patterns}}, $_;
		}
		elsif ( s{^\.}{} ) {
			push @{$CFG->{name}{patterns}}, qr{^(.+\.|)\Q$_\E$};
		}
		elsif ( m{\*} ) {
			$_ = quotemeta $_;
			s{\*}{.+}g;
			push @{$CFG->{name}{patterns}}, qr{^$_$};
		}
		else {
			$CFG->{name}{names}{$_} = 1;
		}
	}
	$CFG->{name}{info} = "[@names]";
	return;
}

# syntax: location [=|~|~*|^~|@] /uri/ { ... }
# = full match
# @ named locatoin
# ^ no regex check
sub location { # context: server
	$CTX eq 'server' or croak "listen could be run in context server";
	my $flag;
	$flag = shift if substr($_[0],0,1) =~ m{(?:=|\^)};
	
	my ($pattern,$code) = @_;
	#local $CTX = local $LOC = {};
	#$code->();
	push @{$CFG->{locations}}, {
		$flag ? ( flag => $flag ) : ( flag => ' ' ),
		UNIVERSAL::isa($pattern,"Regexp")
			? ( pattern => $pattern )
			: ( path => $pattern ),
		code => $code,
	};
}

# context: location
sub alias($) { 
	$CTX eq 'location' or croak "alias could be run in context location";
	$CFG->{alias} = shift;
}

# context: http, server, location, if в location
sub root($) { 
	$CTX =~ m{(?:http|server|location)} or croak "root could be run in context http|server|location";
	$CFG->{root} = shift;
}

# error_page код [код ...] [=|=ответ] uri
sub error_page(@) { # context: http, server, location, if в location
	my $handler = pop;
	my $res;$res = pop if substr($_[-1],0,1) eq '=';
	if ($res) {
		$res =~ s{^=}{};
		$res ||= 200;
	}
	my $e = {
		handler => $handler,
		response => $res,
	};
	$CTX->{error}{$_} = $e for @_;
	
}

http {
	server {
		server_name 'www.example.com';
		listen 8080, default, backlog = 10;
		listen '127.0.0.1:8081';
		root '/home/mons/test';
		location '=','/' => sub {
			return 200;
		};
		location '/' => sub {
			root '/home/mons/test/index';
		};
		location '/path' => sub {
			return 403;
		};
		location qr{^/(\d+)} => sub {
			# ???
		};
	};
	server {
		server_name '.example.com';
		listen '127.0.0.1:8081', default;
	};
	server {
		server_name 'www.another.com', qr{^www\d*\.another\.com$};
		listen '*:8080';
	};
};

__END__
http {
	server {
		listen 8080;
		print 1;
		root '/xxx';
		error_page 404, 405, '=500', '@errors';
		location '@errors', sub {
			
			return 500;
		};
		
		location '/' => sub {
			root '/tmp';
		};
		
		location '/aliased' => sub {
			alias '/tmp';
		};
	};
};
