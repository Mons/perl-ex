#!/usr/bin/perl

use strict;

BEGIN {
	$ENV{HARNESS_PLUGINS} = join ' ',
		grep { require "Test/Run/Plugin/$_.pm" }
		qw(ColorSummary ColorFileVerdicts)
}

if (eval q{use Test::Run::CmdLine::Prove::App;1}) {
	@ARGV='*/t/*.t';
	run();
}
elsif (eval q{use Test::Harness;1}) {
	runtests( <*/t/*.t> );
}
else {
	die "Please install Test::Run::CmdLine or Test::Harness\n";
}
