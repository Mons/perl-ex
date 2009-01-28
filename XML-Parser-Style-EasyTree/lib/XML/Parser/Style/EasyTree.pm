package XML::Parser::Style::EasyTree;

use strict;
use warnings;
use Scalar::Util ();

=head1 NAME

XML::Parser::Style::EasyTree - Parse xml to simple tree

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

	use XML::Parser;
	my $p = XML::Parser->new( Style => 'EasyTree' );

=head1 EXAMPLE

	<root>
		
	</root>

will be

	# ...

=head1 SPECIAL VARIABLES

=over 4

=item $ATTR_PREFIX [ = '-' ]

Allow to set prefix for name of attribute nodes;

	<item attr="value" />
	# will be
	item => { -attr => 'value' };

=item $TEXT_NODE_KEY [ = '#text' ]

Allow to set name for text nodes

	<item><sub attr="t"></sub>Text value</item>
	# will be
	item => { sub => { -attr => "t" }, #text => 'Text value' };

=item %FORCE_ARRAY

Allow to force single nodes to be represented always as arrays.

	# $FORCE_ARRAY{sub} = 1;
	<item><sub attr="t"></sub>Text value</item>
	# will be
	item => { sub => [ { -attr => "t" } ], #text => 'Text value' };

=item %FORCE_HASH

Allow to force text-only nodes to be represented always as hashes.

	# $FORCE_HASH{sub} = 1;
	<item><sub>Text value</sub></item>
	# will be
	item => { sub => { #text => 'Text value' } };

=back

=cut

sub DEBUG { 0 };

our @stack;
our %tree;

our $ATTR_PREFIX       = '-';
our $TEXT_NODE_KEY     = '#text';

our %TEXT = (
	ATTR => '-',
	NODE => '#text',
);

our $STRIP_KEY;

our $FORCE_ARRAY_ALL   = 0;
our %FORCE_ARRAY;

our $FORCE_HASH_ALL   = 0;
our %FORCE_HASH;


sub Init {
    my $xp = shift;
    my $t = $xp->{FunTree} ||= {};
    $t->{stack} = [];
    $t->{tree} = {};
    $t->{context} = { tree => {}, text => [] };
    $t->{opentag} = undef;
	$t->{depth} = 0 if DEBUG;
    return;
}

sub Start {
    my $xp = shift;
    my $t = $xp->{FunTree};
    local *stack    = $t->{stack};
    local *tree     = $t->{tree};
    
	#if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
	my $tag = shift;
    $tag =~ s{$STRIP_KEY}{} if $STRIP_KEY;
	warn "++"x(++$t->{depth}) . $tag if DEBUG;
				
	my $node = {
        name  => $tag,
        tree  => undef,
		text  => [],
    };
    Scalar::Util::weaken($node->{parent} = $t->{context});
    if (@_) {
        my %attr;
        while (my ($k,$v) = splice @_,0,2) {
            $attr{ $TEXT{ATTR}.$k } = $v;
        }
        #$flat[$#flat]{attributes} = \%attr;
        $node->{attrs} = \%attr;
        #warn "Need something to do with attrs on $tag\n";
    };
    $t->{opentag} = 1;
    
    push @stack, $t->{context} = $node;
}

sub End  {
    my $xp = shift;
    my $t = $xp->{FunTree};
    local *stack    = $t->{stack};
    local *tree     = $t->{tree};
    
    #if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
    my $name = shift;
    $name =~ s{$STRIP_KEY}{} if $STRIP_KEY;
    
    #my $node = pop @stack;
    my $text = $t->{context}{text};
    $t->{opentag} = 0;
    
    my $tree = $t->{context}{tree};

    my $haschild = scalar keys %$tree;
    if ( ! $FORCE_ARRAY_ALL ) {
        foreach my $key ( keys %$tree ) {
			warn "$key for $name\n";
            next if $FORCE_ARRAY{$key};
            next if ( 1 < scalar @{ $tree->{$key} } );
            $tree->{$key} = shift @{ $tree->{$key} };
        }
    }
    if ( @$text ) {
		#warn "node $name have text '@$text'";
        if ( @$text == 1 ) {
            # one text node (normal)
            $text = shift @$text;
        }
        else {
            # some text node splitted
            $text = join( ' ', @$text );
        }
        if ( $haschild ) {
            # some child nodes and also text node
            $tree->{$TEXT{NODE}} = $text;
        }
        else {
            # only text node without child nodes
            $tree = $text;
        }
    }
    elsif ( ! $haschild ) {
        # no child and no text
        $tree = "";
    }
    
    # Move up!
    my $child = $tree;
    #warn "parent for $name = $context->{parent}\n";
    my $elem = $t->{context}{attrs};
    my $hasattr = scalar keys %$elem if ref $elem;
    my $forcehash = $FORCE_HASH_ALL || ( $t->{context}{parent}{name} && $FORCE_HASH{$t->{context}{parent}{name}} );
    $t->{context} = $t->{context}{parent};
    
    #warn "$context->{name} have ".Dumper ($elem);
    if ( UNIVERSAL::isa( $child, "HASH" ) ) {
        if ( $hasattr ) {
            # some attributes and some child nodes
            %$elem = ( %$elem, %$child );
        }
        else {
            # some child nodes without attributes
            $elem = $child;
        }
    }
    else {
        if ( $hasattr ) {
            # some attributes and text node
			warn "${name}: some attributes and text node";
            $elem->{$TEXT{NODE}} = $child;
        }
        elsif ( $forcehash ) {
            # only text node without attributes
            $elem = { $TEXT{NODE} => $child };
        }
        else {
            # text node without attributes
            $elem = $child;
        }
    }
    
	warn "--"x($t->{depth}--) . $name if DEBUG;
    push @{ $t->{context}{tree}{$name} ||= [] },$elem;
    $name = $t->{context}{name};
    $tree = $t->{context}{tree} ||= {};
    
    warn "unused args on /$name: @_" if @_;
}

sub Char {
    my $xp = shift;
    my $t = $xp->{FunTree};
    local *stack    = $t->{stack};
    local *tree     = $t->{tree};
    #if ($enc) { @_ = @_; $_ = $enc->encode($_) for @_ };
    my $text = shift;
    
    #do {
    #	local $Data::Dumper::Indent = 0;
    #	local $Data::Dumper::Terse = 1;
    #	warn qq{open="$opentag"; text=}.Dumper($text) if $text =~ /\S/;
    #} if DEBUG_ENCODING;
    #if ($t->{opentag}) {
	$text =~ s{(?:^[\t\s\r\n]+|[\t\s\r\n]+$)}{}sg;
	#warn "text '$text' for $t->{context}{name} to haven @{ $t->{context}{text} }";
    push @{ $t->{context}{text} }, $text if length $text;
    #}else{
		#warn "dropping text '$text': no open node" if length $text;
	#}
    #warn "unused args on char: @_" if @_;
    #warn " @{$ex->{Context}} : char \"$text\" @_\n";
}

sub Final {
    my $xp = shift;
    my $tree = $xp->{FunTree}{context}{tree};
    delete $xp->{FunTree};
    if ( ! $FORCE_ARRAY_ALL ) {
        foreach my $key ( keys %$tree ) {
            next if $FORCE_ARRAY{$key};
            next if ( 1 < scalar @{ $tree->{$key} } );
            $tree->{$key} = shift @{ $tree->{$key} };
        }
    }
    return $tree;
}
        
#eval { $p->parse($$textref); } or Carp::croak "$$textref, $@\n";


1;


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 BUGS

None known

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;
