#!/usr/bin/perl

use lib::abs '../lib';

# redefine constant in tdebug to suppress diagnostics warnings
use constant::abs 'tdebug::DEBUG' => 0;

use tdebug;
use tnodebug;
