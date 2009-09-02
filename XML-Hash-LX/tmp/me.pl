#!/usr/bin/env perl

BEGIN {push @INC, '../lib'};
BEGIN {print "Initial:\n",`ps auxw $$`;}
use XML::Hash::LX;
BEGIN {print "After use:\n",`ps auxww $$`;}

1;
