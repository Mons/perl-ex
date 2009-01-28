# ex::lib
#
# Copyright (c) 200[789] Mons Anderson <mons@cpan.org>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::lib;

=head1 NAME

ex::lib - The same as C<lib>, but makes relative path absolute.

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

Simple use like C<use lib ...>:

	use ex::lib qw(./mylibs1 ../mylibs2);
	use ex::lib 'mylibs';

=head1 THE GOAL

The main reason of this library is transformate relative paths to absolute at the C<BEGIN> stage, and push transformed to C<@INC>.
Relative path basis is not the current working directory, but the location of file, where the statement is.
When using common C<lib>, relative paths stays relative to curernt working directory, 

	# For ex:
	# script: /opt/scripts/my.pl
	use ex::lib '../lib';

	# We run `/opt/scripts/my.pl` having cwd /home/mons
	# The @INC will contain '/opt/lib';

	# We run `./my.pl` having cwd /opt
	# The @INC will contain '/opt/lib';

	# We run `../my.pl` having cwd /opt/lib
	# The @INC will contain '/opt/lib';

Also this module is very useful when writing tests, when you want to load strictly the module from ../lib, respecting the test file.

	# t/00-test.t
	use ex::lib '../lib';

Also this is useful, when you running under C<mod_perl>, use something like C<Apache::StatINC>, and your application may change working directory.
So in case of chdir C<StatINC> fails to reload module if the @INC contain relative paths.

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Mons Anderson.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Mons Anderson, C<< <mons@cpan.org> >>

=cut

use strict;
use lib ();
$ex::lib::VERSION = 0.03;

BEGIN {
	# use constants is heavy :(
	sub DEBUG () { 0 };
	
	# Load Cwd, if exists.
	# There may be an XS version
	eval { require Cwd; };
	if ($@) {
		*abs_path = \&_perl_abs_path;
	}else{
		Cwd->import('abs_path');
	}
}

sub _carp  { require Carp; Carp::carp(@_)  }
sub _croak { require Carp; Carp::croak(@_) }

sub mkapath($) {
	my $depth = shift;
	
	# Prepare absolute base bath
	my ($pkg,$file) = (caller($depth))[0,1];
	warn "file = $file " if DEBUG > 1;
	$file =~ s{[^/]+$}{}s;
	$file = '.' unless length $file;
	warn "base path = $file" if DEBUG > 1;
	#( my $p = $pkg  ) =~ s{::}{/}g;
	#( my $f = $file ) =~ s/\Q$p.pm\E$//i;
	my $f = abs_path($file) . '/';
	warn "source dir = $f " if DEBUG > 1;
	$f;
}

sub transform {
	local $@; # Don't poison $@
	my $prefix;
	map {
		ref || m{^/} ? $_ : do {
			my $lib = $_;
			s{^\./+}{};
			local $!;
			my $abs = ( $prefix ||= mkapath(2) ) . $_;
			$_ = abs_path( $abs ) or _croak("Bad path specification: `$lib' => `$abs'" . ($! ? " ($!)" : ''));
			warn "$lib => $_" if DEBUG > 1;
			$_;
		}
	} @_;
}

sub import {
	shift;
	local $@; # Don't poison $@
	
	_croak("Bad usage. use ".__PACKAGE__." PATH") unless @_;

	@_ = ( lib => transform @_ = @_ );
	warn "use @_\n" if DEBUG > 0;
	goto &lib::import;
	return;
}

sub unimport {
	shift;
	local $@; # Don't poison $@
	_croak("Bad usage. use ".__PACKAGE__." PATH") unless @_;
	@_ = ( lib => transform @_ = @_ );
	warn "no @_\n" if DEBUG > 0;
	goto &lib::unimport;
	return;
}


# From Cwd;

sub _perl_abs_path {
	warn "Using perlish abs_path\n" if DEBUG;
	my $start = @_ ? shift : '.';
	my($dotdots, $cwd, @pst, @cst, $dir, @tst);

	unless (@cst = stat( $start ))
	{
		_croak("$start: $!");
		return '';
	}

	unless (-d _) {
		# Make sure we can be invoked on plain files, not just directories.
		# NOTE that this routine assumes that '/' is the only directory separator.
	
		my ($dir, $file) = $start =~ m{^(.*)/(.+)$}
		or return cwd() . '/' . $start;
	
		# Can't use "-l _" here, because the previous stat was a stat(), not an lstat().
		if (-l $start) {
			my $link_target = readlink($start);
			die "Can't resolve link $start: $!" unless defined $link_target;
			
			require File::Spec;
				$link_target = $dir . '/' . $link_target
					unless File::Spec->file_name_is_absolute($link_target);
			
			return abs_path($link_target);
		}
		
		return $dir ? abs_path($dir) . "/$file" : "/$file";
	}

	$cwd = '';
	$dotdots = $start;
	do {
		$dotdots .= '/..';
		@pst = @cst;
		local *PARENT;
		unless (opendir(PARENT, $dotdots)) {
			_carp("opendir($dotdots): $!");
			return '';
		}
		unless (@cst = stat($dotdots)) {
			_carp("stat($dotdots): $!");
			closedir(PARENT);
			return '';
		}
		if ($pst[0] == $cst[0] && $pst[1] == $cst[1]) {
			$dir = undef;
		}
		else {
			do {
				unless (defined ($dir = readdir(PARENT))) {
					_carp("readdir($dotdots): $!");
					closedir(PARENT);
					return '';
				}
				$tst[0] = $pst[0]+1 unless (@tst = lstat("$dotdots/$dir"))
			}
			while ($dir eq '.' || $dir eq '..' || $tst[0] != $pst[0] ||
			$tst[1] != $pst[1]);
		}
		$cwd = (defined $dir ? "$dir" : "" ) . "/$cwd" ;
		closedir(PARENT);
	} while (defined $dir);
	chop($cwd) unless $cwd eq '/'; # drop the trailing /
	$cwd;
}

1;
