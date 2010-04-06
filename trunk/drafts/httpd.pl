#!/usr/bin/env perl

use uni::perl ':dumper';
use lib::abs 'lib';
use AE;
use AE::HTTPD;
use AE::HTTPD::DAV;
use AE::HTTPD::PP;
use AE::HTTPD::Static;

my $root = lib::abs::path 'root';
# my $srv = AE::HTTPD->new(request => AE::HTTPD::PP->new(
# 	pass    => 'http://id-planet.rambler.ru/api/rest/user',
# 	headers => { Host => 'id-planet.rambler.ru', 'Content-type' => 'text/xml' },
# 	
# 	#pass    => 'http://www.google.com',
# 	#headers => { Host => 'www.google.com', },
# 	timeout => 10,
# ));
my $srv = AE::HTTPD->new(request => AE::HTTPD::DAV->new($root));
#my $srv = AE::HTTPD->new(request => AE::HTTPD::Static->new($root));
$srv->start;
AE::cv->recv;
