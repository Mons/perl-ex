# ex::lib
#
# Copyright (c) 2007 Mons Anderson <inthrax@gmail.com>. All rights reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package ex::lib;

=head1 NAME

ex::lib - The same as C<lib>, but makes relative path absolute.

=head1 SYNOPSIS

    use ex::lib qw(./mylibs1 ../mylibs2);
    use ex::lib 'mylibs';

=over 4

=cut

use strict;

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

sub import {
	shift;
    local $@; # Don't poison $@
	
	# Prepare absolute base bath
	my ($pkg,$file) = (caller(0))[0,1];
    ( my $p = $pkg  ) =~ s{::}{/}g;
    ( my $f = $file ) =~ s/\Q$p.pm\E$//i;
	if ($f !~ m{^/} ) {
		$f =~ s{\./}{};
		$f = abs_path('./'.$f) if defined &abs_path;
	}
    $f .= '/' if $f and $f !~ m{/$};
	
	
	_croak("Bad usage. use ".__PACKAGE__." PATH") unless @_;
	for (@_) {
		my $lib = $_;
		$lib =~ s{^\./}{};
	    $lib = "$f$lib";
		$lib =~ s{\'}{\\'}g;
		
		warn "use explicit lib: '$lib'\n" if DEBUG;
		_croak("Bad path specification") unless $lib;
	    eval qq{use lib '$lib'};
	    _croak($@) if $@;
	}
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
    do
    {
	$dotdots .= '/..';
	@pst = @cst;
	local *PARENT;
	unless (opendir(PARENT, $dotdots))
	{
	    _carp("opendir($dotdots): $!");
	    return '';
	}
	unless (@cst = stat($dotdots))
	{
	    _carp("stat($dotdots): $!");
	    closedir(PARENT);
	    return '';
	}
	if ($pst[0] == $cst[0] && $pst[1] == $cst[1])
	{
	    $dir = undef;
	}
	else
	{
	    do
	    {
		unless (defined ($dir = readdir(PARENT)))
	        {
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
