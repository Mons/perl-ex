package AE::HTTPD::Req;

use uni::perl;

our %ERR = (
	404 => 'Not Found',
	405 => 'Method Not Allowed',
	409 => 'Conflict',
	412 => 'Precondition Failed',
 	415 => 'Unsupported Media Type',
 	500 => 'Internal Server Error',
);

sub new {
	my $pk = shift;
	my $self = bless {@_},$pk;
	$self;
}

sub response {
	my $self = shift;
	#warn "Response @_";
	$self->{server} or return %$self = ();
	$self->{server}->response($self, @_);
	$self->dispose;
}

sub error {
	my $self = shift;
	my $code = shift;
	my $msg = shift || $ERR{$code} || "Code-$code";
	$self->{server} or return %$self = ();
	$self->{server}->error($self, $code,$msg, @_);
	$self->dispose;
}

sub dispose {
	my $self = shift;
	return %$self = ();
}

sub DESTROY {
	my $self = shift;
	$self->{server} or return %$self = ();
	$self->{server}->error($self, 500, "No response", {}, "No response");
}

package AE::HTTPD;

use uni::perl ':dumper';
use AE;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Scalar::Util qw(weaken);

use Sys::Sendfile;
use HTTP::HeaderParser::XS;
use CGI::Cookie::XS;


sub new {
	my $pk = shift;
	my $self = bless {
		keep_alive => 1,
		@_,
	},$pk;
	$self->{host} //= '0.0.0.0';
	$self->{port} //= 8080;
	return $self;
}

sub start {
	my $self = shift;
	tcp_server $self->{host}, $self->{port}, sub {
		my $fh = shift or return warn "couldn't accept client: $!";
		my ($host, $port) = @_;
		$self->accept($fh,$host, $port);
	}, sub {
		1024;
	};
	warn "Ready";
}

sub accept :method {
	my ($self,$fh,$host,$port) = @_;
	my $id = int $fh;
	#warn "accept";
	my $h = AnyEvent::Handle->new(
		fh         => $fh,
		on_eof     => sub { warn "EOF";    delete $self->{con}{$id} },
		on_error   => sub { warn "ERR @_"; delete $self->{con}{$id} },
	);
	{
		weaken $self;
		$self->{con}{$id} = {
			fh  => $fh,
			h   => $h,
			r   => [],
			$self->{keep_alive} ? (
				ka  => AE::timer 300,0,sub {
					$self or return;
					delete $self->{con}{$id};
				},
			) : (),
		};
		$self->read_header($id);
	}
	return;
}

sub read_header {
	my ($self,$id) = @_;
	my $con = $self->{con}{$id};
	return warn "no connection for $id" unless $con;
	weaken $self;
	#warn dumper $con;
	$con->{h}->push_read(line => sub {
		$self or return;
		shift;
		my $line = shift;
		if ($line =~ /(\S+) \040 (\S+) \040 HTTP\/(\d+)\.(\d+)/xso) {
			my ($meth, $url, $vm, $vi) = ($1, $2, $3, $4);
			$con->{method} = $meth;
			$con->{uri} = $url;
			$self->read_headers($id);
		}
		elsif ($line eq '') {
			$self->read_header($id);
		}
		else {
			$self->error($id, 400, "Bad Request", {}, undef, 'fatal');
		}
	});
}

# loosely adopted from AnyEvent::HTTP:
sub _parse_headers {
	my ($header) = @_;
	my $hdr;

	$header =~ y/\015//d;

	while ($header =~ /\G
		([^:\000-\037]+):
		[\011\040]*
		( (?: [^\012]+ | \012 [\011\040] )* )
		\012
	/sgcxo) {

		$hdr->{$1} .= ",$2"
	}

	return undef unless $header =~ /\G$/sgxo;

	for (keys %$hdr) {
		substr $hdr->{$_}, 0, 1, '';
		# remove folding:
		$hdr->{$_} =~ s/\012([\011\040])/$1/sgo;
	}

	$hdr
}

sub read_headers {
	my ($self,$id) = @_;
	my $con = $self->{con}{$id};
	$con->{h}->unshift_read (
		line => qr{(?<![^\012])\015?\012}o,
		sub {
			my ($hdl, $data) = @_;
			my $htxs = HTTP::HeaderParser::XS->new( \("GET / HTTP/1.0\r\n".$data."\r\n") );
			my $hdr;
			if ($htxs) {
				$hdr = $htxs->getHeaders;
			} else {
				$hdr = _parse_headers ($data);
			}

			unless (defined $hdr) {
				$self->error ($id, 599 => "garbled headers");
			}
			$hdr->{Cookie} = CGI::Cookie::XS->parse($hdr->{Cookie}) if exists $hdr->{Cookie};
			#warn dumper $hdr;
			push @{ $self->{con}{$id}{r} }, AE::HTTPD::Req->new(
				id      => $id,
				server  => $self,
				method  => delete $con->{method},
				uri     => delete $con->{uri},
				host    => $hdr->{Host},
				headers => $hdr,
			);
			my $r = $con->{r}[-1];
			weaken($con->{r}[-1]);
			unless (lc $hdr->{Connection} =~ /keep-alive/) {
				delete $con->{ka};
			}
			
			if (defined $hdr->{'Content-length'}) {
				#warn "reading content $hdr->{'Content-length'}";
				$con->{h}->unshift_read (chunk => $hdr->{'Content-length'}, sub {
					my ($hdl, $data) = @_;
					$self->handle_request($r, $data);
					$self->read_header($id) if $con->{ka};
				});
			} else {
				$self->handle_request($r);
				$self->read_header($id) if $con->{ka};
			}
		}
	);
}

sub handle_request {
	my ($self,$r,$data) = @_;
	weaken(my $x = $r);
	$r->{t} = AE::timer 2,0,sub {
		$x or return;
		warn "Fire timeout timer";
		$x->error(504, "Gateway timeout");
	};
	$self->{request}->($r,$data);
}

sub error {
	my ($self, $r, $code, $msg, $hdr, $content, $fatal) = @_;
	#warn "Send error $code to $r->{id}";
	if ($code !~ /^(1\d\d|204|304)$/o) {
		unless (defined $content) { $content = "$code $msg" }
		$hdr->{'Content-Type'} = 'text/plain';
	}

	$self->response( $r, $code, $msg, $hdr, $content );
	if ($fatal) {
		delete $self->{con}{$r->{id}};
	}
}

sub response {
	my ($self, $r, $code, $msg, $hdr, $content) = @_;
	my $id = $r->{id};
	my $con = exists $self->{con}{$id} ? $self->{con}{$id} : undef;
	#warn "Send response $code $msg to $id ($con)";
	$con or return;
	if (@{$con->{r}} and $con->{r}[0] == $r) {
		shift @{ $con->{r} };
	} else {
		$r->{ready} = [ $code, $msg, $hdr, $content ];
		return;
	}

	my $res = "HTTP/1.0 $code $msg\015\012";
	if (ref $content eq 'HASH') {
		if ($content->{sendfile}) {
			$hdr->{'Content-Length'} = -s $content->{sendfile};
		}
	}
	#$hdr->{'Expires'}        = $hdr->{'Date'}
	#                         = _time_to_http_date time;
	$hdr->{'Cache-Control'}  = "max-age=0";
	$hdr->{'Connection'}     = $self->{keep_alive} && $con->{ka} ? 'Keep-Alive' : 'close';

	$hdr->{'Content-Length'} = length $content
		if not (defined $hdr->{'Content-Length'}) && not ref $content;

	unless (defined $hdr->{'Content-Length'}) {
		# keep alive with no content length will NOT work.
		delete $self->{keep_alive};
	}

	while (my ($h, $v) = each %$hdr) {
		$res .= "$h: $v\015\012";
	}

	$res .= "\015\012";

=for rem
	if (ref ($content) eq 'CODE') {
		weaken $self;
	
		my $chunk_cb = sub {
			my ($chunk) = @_;
	
			return 0 unless defined ($self) && defined ($self->{hdl});
	
			delete $self->{transport_polled};
	
			if (defined ($chunk) && length ($chunk) > 0) {
				$self->{hdl}->push_write ($chunk);
	
			} else {
				$self->response_done;
			}
	
			return 1;
		};
	
		$self->{transfer_cb} = $content;
	
		$self->{hdl}->on_drain (sub {
			return unless $self;
	
			if (length $res) {
				my $r = $res;
				undef $res;
				$chunk_cb->($r);
	
			} elsif (not $self->{transport_polled}) {
				$self->{transport_polled} = 1;
				$self->{transfer_cb}->($chunk_cb) if $self;
			}
		});
	
	}
	else {
=cut
		$res .= $content unless ref $content;
		warn "Send response $code on $r->{method} $r->{uri}";
		$con->{h}->push_write($res);
		if (ref $content eq 'HASH') {
			if ($content->{sendfile}) {
				my $file = $content->{sendfile};
				#$hdr->{'Content-Length'} = -s $file;
				open my $f, '<', $content->{sendfile};
				sendfile $con->{fh}, $f, 0 or warn "sendfile: $!";
				close $f;
			}
		}
		#$con->{h}->destroy;
		#$self->response_done;
	#   }
	if (!$con->{ka} or lc($hdr->{connection}) =~ /close/) {
		#warn "Closing Connection: close";
		$con->{h}->destroy();
		delete $self->{con}{$id};
	} else {
		if ( @{$con->{r}} and $con->{r}[0]{ready}) {
			$self->response($con->{r}[0],@{$con->{r}[0]{ready}});
		}
	}
}

1;
