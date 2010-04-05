#!/usr/bin/env perl

package AE::HTTPD::Req;

sub new {
	my $pk = shift;
	my $self = bless {@_},$pk;
}

package AE::HTTPDX;
use uni::perl ':dumper';
use AE;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Scalar::Util qw(weaken);

sub new {
	my $self = bless {@_},shift;
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
	my $h = AnyEvent::Handle->new(
		fh       => $fh,
		on_eof   => sub { warn "EOF"; delete $self->{con}{$id} },
		on_error   => sub { warn "ERROR @_"; delete $self->{con}{$id} },
	);
	$self->{con}{$id} = {
		id => $id,
		fh => $fh,
		h  => $h,
	};
	$self->read_header($id);
}

sub error {
   my ($self, $id, $code, $msg, $hdr, $content) = @_;

   if ($code !~ /^(1\d\d|204|304)$/o) {
      unless (defined $content) { $content = "$code $msg" }
      $hdr->{'Content-Type'} = 'text/plain';
   }

   $self->response ($id, $code, $msg, $hdr, $content);
}



sub read_header {
	my ($self,$id) = @_;
	my $con = $self->{con}{$id};
	weaken $self;
	warn "Want headers";
	$con->{h}->push_read(line => sub {
		$self or return;
		shift;
		my $line = shift;
		if ($line =~ /(\S+) \040 (\S+) \040 HTTP\/(\d+)\.(\d+)/xso) {
			my ($meth, $url, $vm, $vi) = ($1, $2, $3, $4);
			warn "$meth $url $vm.$vi";
			$con->{head} = [$meth,$url];
			$self->read_headers($id);
		}
		elsif ($line eq '') {
			$self->push_header($id);
		}
		else {
			$self->error($id, 400, "Bad Request");
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

      $hdr->{lc $1} .= ",$2"
   }

   return undef unless $header =~ /\G$/sgxo;

   for (keys %$hdr) {
      substr $hdr->{$_}, 0, 1, '';
      # remove folding:
      $hdr->{$_} =~ s/\012([\011\040])/$1/sgo;
   }
   $hdr->{cookie} = CGI::Cookie::XS->parse($hdr->{cookie});

   $hdr
}


sub read_headers {
	my ($self,$id) = @_;
	my $con = $self->{con}{$id};
	$con->{h}->unshift_read (line =>
      qr{(?<![^\012])\015?\012}o,
      sub {
         my ($hdl, $data) = @_;
         my $hdr = _parse_headers ($data);

         unless (defined $hdr) {
            $self->error ($id, 599 => "garbled headers");
         }

         $con->{hdr} = $hdr;

         if (defined $hdr->{'content-length'}) {
            $self->{hdl}->unshift_read (chunk => $hdr->{'content-length'}, sub {
               my ($hdl, $data) = @_;
               $self->handle_request ($id, $data);
            });
         } else {
            $self->handle_request ($id);
         }
      }
   );
}

use Sys::Sendfile;
use CGI::Cookie::XS;

sub handle_request {
	my ($self,$id) = @_;
	my $con = $self->{con}{$id};
	warn dumper $con;
	
	$self->response($id, 200, "OK", {}, { sendfile => __FILE__ });
}

sub response {
	my ($self, $id, $code, $msg, $hdr, $content) = @_;
	my $con = $self->{con}{$id} or return;

	my $res = "HTTP/1.0 $code $msg\015\012";
	if (ref $content eq 'HASH') {
		if ($content->{sendfile}) {
			my $file = $content->{sendfile};
			$hdr->{'Content-Length'} = -s $file;
			#$content = '';
		}
	}
	#$hdr->{'Expires'}        = $hdr->{'Date'}
	#                         = _time_to_http_date time;
	$hdr->{'Cache-Control'}  = "max-age=0";
	$hdr->{'Connection'}     = $self->{keep_alive} ? 'Keep-Alive' : 'close';

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
		warn "Send response $res";
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
}


package main;

use uni::perl ':dumper';
use AE;
use AnyEvent::Socket;

my $srv = AE::HTTPDX->new();
$srv->start;
AE::cv->recv;
