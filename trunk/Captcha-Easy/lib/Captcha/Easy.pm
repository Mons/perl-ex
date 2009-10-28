package Captcha::Easy;

use 5.008008;
use strict;
use warnings;

=head1 NAME

Captcha::Easy - Simple and fast captcha

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Captcha::Easy;

    my $captcha = Captcha::Easy->new(
        temp   => '/path/to/storage',
        reuse  => 1, # reuse expired files
        salt   => 'your secret',
        font   => '/path/to/font.ttf',
        expire => 60*30, # 30 min
    );
    my $hash = $captcha->make;
    my ($w1,$w2,$rest) = split //,$hash,3;
    print qq{<img src="http://path.to.temp/$w1/$w2/$rest.png" />};
    
    ...
    
    my $code = $captcha->check($word,$hash);
    if    ($code ==  1) { valid }
    elsif ($code ==  0) { wrong word }
    elsif ($code == -1) { word correct, but captcha was already used (i.e. file removed) }
    elsif ($code == -2) { word correct, but captcha was expired (i.e. file mtime < time - $captcha->{epire} ) }
    else                { something strange happens }

=cut

use Imager;
use Imager::Fill;
use Digest::SHA1 qw(sha1_hex);
use Carp qw(croak carp);
use File::Find qw(find);
our ($FONT_PATH,$FONT,$TMP,$EXP,$USE_EXP);

use constant pi => 3.141592;
BEGIN {
	( my $f = __FILE__ ) =~ s/\.pm$//i;
	$FONT_PATH = $f;
	$FONT = 'font';
	$EXP  = 60 * 15; # 15 min
	$USE_EXP = 1;
}

=head2 new (%args)

Args: font, temp, reuse, expire, salt, debug, length

=cut

sub new {
	my $pkg = shift;
	my $self = bless {
		font   => $FONT_PATH.'/'.$FONT.'.ttf',
		$USE_EXP ? (expire => $EXP) : (),
		reuse => 1,
		salt  => '',
		debug => 0,
		length => 7,
		@_
	}, $pkg;
	length $self->{salt}
		or carp "It's unsecure to use captcha without salt";
	-d $self->{temp} and -w $self->{temp}
		or croak "CAPTCHA: Please, create temp dir ($self->{temp}) for images or set temp option";
	-f $self->{font}
		or croak "CAPTCHA: Please, put font file to ($self->{font}) or set font option";
	
	
	$self;
}

sub _d { # debug routine
	my $self = shift;
	$self->{debug} or return;
	ref $self or warn("bad args for d(): $self @_ at @{[ (caller)[1,2] ]}"),return;
	local $_=shift;
	s{\r?\n$}{}sg;
	s{\r?\n}{\\n}sg;
	my $msg = do {
		no warnings;
		sprintf "%s [%s] %s (%s)\n", scalar(localtime),$ENV{REMOTE_ADDR},$_,$ENV{REQUEST_URI};
	};
	warn "$msg";
	$self->{debug} > 1 or return;
	local ($@,$!);
	unless (exists $self->{logfh}) {
		open $self->{logfh},'>>',"$self->{temp}/log" or do { warn "CAPTCHA: log error: $!";return };
		chmod oct(664),"$self->{temp}/log";
		require IO::Handle;
		$self->{logfh}->autoflush(1);
	}
	$self->{logfh} or return;
	print { $self->{logfh} } $msg;
}

=head2 word([$length])

    Generate captcha word

=cut

sub word {
	my $self = shift;
	my $size = shift || $self->{length};
	$size > 0 or croak "Word needs size";
	my %c;
	#$c{0} = [qw(e u i o a oo ae)];
	$c{0} = [qw(e u i o a ae)];
	$c{1} = [qw(r s d l n m )];
	$c{1} = [qw(r s l n m )];
	$c{2} = [qw(q w t p f g h j k z x c v b)];
	my $s = '';
	my $nc = int rnd(1,3);
	my $cs = 1;
	my %lc;
	@lc{0,1,2} = ('','','');
	my $loops;
	while (++$loops < 100 and length($s) < $size) {
		if ($nc < 0) {
			$cs = $cs == 0 ? int rnd(1,3) : 0;
			$nc = $cs == 0 ? 0 : $cs == 1 ? int rnd(1,2) : 0;
		}
		my $set = $c{$cs};
		my $char;
		do {
			$char = $set->[ int rnd(0,0+@$set) ];
		} while ( ++$loops < 100 and $char eq $lc{$cs} or ( $lc{$cs} and ( index($lc{$cs},$char) != -1 or index($char,$lc{$cs}) != -1 ) ) );
		next if length($s) + length($char) > $size;
		$nc -= length($char);
		$lc{$cs} = $char;
		$s .= $char;
		$nc = -1 if length($char) > 1;
	}
	if ( $loops >= 100 ) {
		$self->_d("Word terminated abnormally with $s");
		$s = substr($s,0,7);
	} else {
		#$self->_d("Loop exit val: $loops");
	}
	return uc($s);
}

sub rnd($$)  { $_[0] + rand() * ( $_[1] - $_[0] ); }

sub image {
	#my ($w,$h) = (200,70);
	my ($self,$word) = @_;
	my ($w,$h) = (160,56);
	my $image  = Imager->new(xsize => $w, ysize => $h);
	my $font   = Imager::Font->new(
		file => $self->{font},
		size => int($h/2),
	) or croak "no font";
	my $bbox
		= $font->bounding_box( string=> $word, canon => 1 );
	my $tw = $bbox->display_width;
	my $th = $bbox->text_height;
	my $bg = int rnd (0,0x606060); my $fg = ( ~ $bg ) & 0xFFFFFF;
	$_ = Imager::Color->new(sprintf('#%06X',$_)) for $bg,$fg;
	$image->box(fill => Imager::Fill->new( solid => $bg ));
	$image->string(
		font => $font,
		color => $fg,
		x => int(($w - $tw)/2),
		y => int(($h - $th)/2) + $th,
		aa => 1,
		string => $word,
	) or die "string: ".$image->errstr;
	return $self->transform($image);
}

sub transform {
	my ($self,$src) = @_;
	my $image = $src->scale( scalefactor => 1.25 );
	$image->filter( type => 'gaussian', stddev => 1.5) or die $image->errstr;
	my $width = $image->getwidth;
	my $height = $image->getheight;
	my $fuzzy = Imager::transform2({
		constants => {
			am1 => rnd(6,8),
			fq1 => pi / $width * 1.05 * rnd( 0.95,1.05 ),
			ph1 => pi + rnd( -pi(),pi ),
			fq2 => pi / $height * 2.5 * rnd(0.95,1.05),
			ph2 => pi/2 + rnd( -pi()/4,pi/4 ),
			am2 => rnd( 6,8 ),
			fq3 => pi / $width * 3 * rnd( 0.95,1.05 ),
			ph3 => 0 + rnd( -pi(),pi ),
			fq4 => pi / $height * rnd( 0.95,1.05 ),
			ph4 => pi + rnd( -pi()/8,pi/8 ),
		},
		#expr => 'pix = getp1( x+am1*(sin(x*fq1+ph1)+sin(y*fq2+ph2)), y+am2*(sin(x*fq3+ph3)+sin(y*fq4+ph4))); return if(value(pix)>0,pix,getp1(1,1))',
		rpnexpr => 'x fq1 * ph1 + sin  y fq2 * ph2 + sin +  am1 * x +   x fq3 * ph3 + sin  y fq4 * ph4 + sin +  am2 * y +   getp1 !pix @pix value 0 gt @pix 0 0 getp1 ifp',
	}, $image) or die "transform2 failed: $Imager::ERRSTR";
	return $fuzzy->scale( scalefactor=> 0.8 ) or die $fuzzy->errstr;
}

sub sanity {
	my $self = shift;
	local $_ = uc shift;
	s{^\s+|\s+$}{}sg;
	tr/015DK/OLSOX/;
	$_;
}

sub encrypt {
	my $self = shift;
	my $word = shift;
	return sha1_hex( $self->sanity( $word ).$self->{salt} );
}

sub generate {
	my $self = shift;
	my $word = shift || $self->word($self->{length});#only for testing
	my $img  = $self->image($word);
	my $sha  = $self->encrypt($word);
	$self->_d("captcha($word)=$sha");
	return ($sha,$img);
}

sub save_file {
	my $self = shift;
	my $um = umask(0);
	eval {
		my ($w,$i) = @_;
		my ($w1,$w2,$rest) = split //,$w,3;
		unless (-d "$self->{temp}/$w1")     { mkdir "$self->{temp}/$w1"    , oct 1771 or croak "CAPTCHA: Cant create temp: $!" }
		unless (-d "$self->{temp}/$w1/$w2") { mkdir "$self->{temp}/$w1/$w2", oct 1771 or croak "CAPTCHA: Cant create temp: $!" }
		my $f = "$self->{temp}/$w1/$w2/$rest.png";
		$i->write( file => $f ) or croak "captcha save failed: ".$i->errstr;
		chmod (oct(664),$f) or warn "captcha chmod $f failed: $!";
	};
	die $@ if $@;
	umask($um);
}

=head2 check

Args: $code, $hash

Returns 1 if $code is a valid text for $hash 

=cut

sub check {
	my $self = shift;
	local $!;
	my $w = $self->encrypt( my $s = shift );
	#$self->sanity( shift );
	my $hash = shift;
	my ($w1,$w2,$rest) = split //,$w,3;
	if ($hash ne $w) {
		$self->_d("Wrong hash: $w <=> $hash");
		$self->remove($hash);
		return 0;
	};
	my $f = "$self->{temp}/$w1/$w2/$rest.png";
	my $r;
	if ( ! -e $f ){
		$self->_d("($s) Non-existing file $f");
		return -1;
	}
	elsif (defined $self->{expire} and time - (stat($f))[9] > $self->{expire}) {
		$self->_d("($s) Expired file $f");
		$r = -2; # expired
	}
	else {
		$self->_d("($s) OK $f");
		$r = 1;
	}
	$self->remove($w);
	return $r;
}

sub remove {
	my $self = shift;
	my $hash = shift;
	my ($w1,$w2,$rest) = split //,$hash,3;
	my $f = "$self->{temp}/$w1/$w2/$rest.png";
	local $!;
	unlink $f or do {
		$self->_d("Can't delete file $f: $!");
	};
	rmdir "$self->{temp}/$w1/$w2" and rmdir "$self->{temp}/$w1";
	return;
}

sub data {
	my $self = shift;
	my $hash = shift;
	return unless $hash =~ /^[\da-f]{40}$/;
	my ($w1,$w2,$rest) = split //,$hash,3;
	open my $f, '<',"$self->{temp}/$w1/$w2/$rest.png" or return;
	my $data = do { local $/; <$f> };
	close $f;
	return $data;
}

sub get_old_unused() {
	my $self = shift;
	defined $self->{expire} or return;
	my $found;
	my $t = time - int ( $self->{expire}*0.5 );
	SEARCH: {
		find ({
			wanted => sub {
				return if !-f || length $_ < 40 || (stat)[9] > $t;
				$found = $_;
                ( $File::Find::prune = 1 )

			},
			no_chdir => 1,
		},$self->{temp});
	}
	return unless $found;
	utime(time,time,$found);
	for($found){
		s{^\Q$self->{temp}/\E}{};
		s{\.png$}{};
		s{/}{}g;
	}
	$self->_d("Found existing captcha `$found'");
	return $found;
}

=head2 make

Creates CAPTCHA and returns hash code for this CAPTCHA

=cut

sub make {
	my $self = shift;
	
	if (!@_ and $self->{reuse} and my $ex = $self->get_old_unused()) {
		return $ex;
	} else {
		my ($w,$i) = $self->generate(@_);
		$self->save_file($w,$i);
		return $w;
	}
}


=head1 AUTHOR

Mons Anderson, C<< <mons at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mons Anderson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Captcha::Easy
