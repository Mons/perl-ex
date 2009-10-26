#
#===============================================================================
#
#         FILE:  01-create.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (), <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  1.0
#      CREATED:  26.10.2009 19:19:17 MSK
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 3;                      # last test to print

use Captcha::Easy;

my $captcha = Captcha::Easy->new( temp => 't/tmp');
my ($hash) = $captcha->generate( 'test11' );;
ok $hash;
ok $captcha->check( 'test11', $hash );
ok !$captcha->check( 'test12', $hash );

