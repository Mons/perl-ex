#!/usr/bin/env perl

use uni::perl ':dumper';
use AE;
use AnyEvent::HTTP;
use Test::More tests => 28;

my $cv = AE::cv;
#my $uri = test.gif';
sub rq (%) {
	my ($method,$file,%args) = @_;
	my $host = 'http://localhost:6789/';
	$cv->begin;
	http_request
		$method => $host.$file,
		headers => {
			($args{acl} ? ( 'x-acl' => $args{acl} ) : ()),
			($args{time} ? ( 'x-time' => $args{time} ) : ()),
			($args{to} ? ( 'destination' => $host.$args{to} ) : ()),
		},
		body => $args{body},
		cb => sub {
			shift;
			$args{cb}(shift);
			$cv->end;
		}
	;
}

my $time = time-120;
my $time2 = time-60;
my $time3 = time-60*3;

rq MKCOL => 'something/', acl => '0755', cb => sub {
	my $h = shift;
	is $h->{Status},'201', 'mkcol ok';
	is $h->{'x-acl'}, '0755', 'acl mkcol';
	rq DELETE => 'something/', cb => sub {
		like $h->{Status},qr/^20[14]$/, 'rmdir ok';
	};
};

rq PUT => 'test.gif', body => 'x'x1000, acl => '0751', time => $time, cb => sub {
	my $h = shift;
	like $h->{Status},qr/^20[14]$/, 'put ok';
	is $h->{'x-acl'}, '0751', 'acl during put';
	is $h->{'x-time'}, $time, 'mtime during put';
	#diag dumper $h;
	#return;
	rq OPTIONS => 'test.gif', cb => sub {
		my $h = shift;
		is $h->{'x-acl'}, '0751', 'acl after put';
		is $h->{'x-time'}, $time, 'mtime after put';
		rq OPTIONS => 'test.gif', acl => '0001', time => $time2, cb => sub {
			my $h = shift;
			is $h->{'x-acl'}, '0001', 'acl after chmod';
			is $h->{'x-time'}, $time2, 'mtime after chmod';
			rq OPTIONS => 'test.gif', cb => sub {
				my $h = shift;
				is $h->{'x-acl'}, '0001', 'acl after chmod';
				is $h->{'x-time'}, $time2, 'mtime after chmod';
				rq OPTIONS => 'test.gif', acl => '640', cb => sub {
					my $h = shift;
					is $h->{'x-acl'}, '0640', 'acl after chmod 001';
					
					my $tx = AE::cv {
						rq DELETE => 'test.gif' => cb => sub {
							my $h = shift;
							is $h->{Status},204, 'delete ok';
						};
					};
					$tx->begin;
					rq COPY => 'test.gif', to => 'testx.gif', cb => sub {
						my $h = shift;
						is $h->{Status},'204', 'copy ok';
						is $h->{'x-acl'}, '0640', 'acl after copy';
						is $h->{'x-time'}, $time2, 'mtime after copy';
						rq MOVE => 'testx.gif', to => 'testx1.gif', cb => sub {
							my $h = shift;
							is $h->{Status},'204', 'move ok';
							is $h->{'x-acl'}, '0640', 'acl after move';
							is $h->{'x-time'}, $time2, 'mtime after move';
							rq DELETE => 'testx1.gif' => cb => sub {
								my $h = shift;
								is $h->{Status},204, 'delete x ok';
								$tx->end;
							};
						};
					};
					$tx->begin;
					rq COPY => 'test.gif', to => 'testy.gif', time => $time, acl => '0600', cb => sub {
						my $h = shift;
						is $h->{Status},'204', 'copy ok';
						is $h->{'x-acl'}, '0600', 'acl after copy + acl';
						is $h->{'x-time'}, $time, 'mtime after copy + acl';
						rq MOVE => 'testy.gif', to => 'testy1.gif', time => $time3, acl => '0604', cb => sub {
							my $h = shift;
							is $h->{Status},'204', 'move ok';
							is $h->{'x-acl'}, '0604', 'acl after move + acl';
							is $h->{'x-time'}, $time3, 'mtime after move + acl';
							rq DELETE => 'testy1.gif' => cb => sub {
								my $h = shift;
								is $h->{Status},204, 'delete y ok';
								$tx->end;
							};
						};
					};
					
				};
			};
		}
	}
};
$cv->recv;
