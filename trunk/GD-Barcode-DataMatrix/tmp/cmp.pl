#!/usr/bin/perl

use strict;
use ex::lib '../lib';

my ($text,$type,$size) = @ARGV;
system("script/barcode $text $type $size");
system("cd java;java prog $text $type $size;cd -");
