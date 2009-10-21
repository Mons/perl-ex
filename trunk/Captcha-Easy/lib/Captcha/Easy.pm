package Captcha::Easy;

use strict;
use warnings;

=head1 NAME

Captcha::Easy - The great new Captcha::Easy!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Captcha::Easy;

    my $foo = Captcha::Easy->new();
    ...

=cut

use strict;
use Imager;
use Imager::Fill;
use Digest::SHA1 qw(sha1_hex);
use Carp qw(croak carp);
use File::Find qw(find);
use IO::Handle;
our ($FONT_PATH,$FONT,$TMP,$EXP,$USE_EXP);

use constant pi => 3.141592;
BEGIN {
	( my $f = __FILE__ ) =~ s/\.pm$//i;
	$FONT_PATH = $f;
	$FONT = 'font';
	$TMP  = '/opt/tmp/captcha';
	$EXP  = 60 * 15; # 15 min
	$USE_EXP = 1;
}

sub new {
	my $pkg = shift;
	my $self = bless {
		font   => $FONT_PATH.'/'.$FONT.'.ttf',
		$USE_EXP ? (expire => $EXP) : (),
		temp   => $TMP,
		reuse => 1,
		@_
	}, $pkg;
	-d $self->{temp} and -w $self->{temp}
		or croak "CAPTCHA: Please, create temp dir ($self->{temp}) for images or set temp option";
	-f $self->{font}
		or croak "CAPTCHA: Please, put font file to ($self->{font}) or set font option";
	
	
	$self;
}

sub d {
	my $self = shift;
	ref $self or warn("bad args for d(): $self @_ at @{[ (caller)[1,2] ]}"),return;
	local ($@,$!);
	unless (exists $self->{logfh}) {
		open $self->{logfh},'>>',"$self->{temp}/log" or do { warn "CAPTCHA: log error: $!";return };
		chmod oct(664),"$self->{temp}/log";
		$self->{logfh}->autoflush(1);
	}
	$self->{logfh} or return;
	local $_=shift;
	s{\r?\n$}{}sg;
	s{\r?\n}{\\n}sg;
	no warnings;
	warn sprintf "%s [%s] %s (%s)\n", scalar(localtime),$ENV{REMOTE_ADDR},$_,$ENV{REQUEST_URI};
	printf { $self->{logfh} } "%s [%s] %s (%s)\n",scalar(localtime),$ENV{REMOTE_ADDR},$_,$ENV{REQUEST_URI};
}

sub word {
	my $self = shift;
	my $size = shift || 7;
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
		$self->d("Word terminated abnormally with $s");
		$s = substr($s,0,7);
	} else {
		#$self->d("Loop exit val: $loops");
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

sub generate {
	my $self = shift;
	my $word = $self->word(6);
	my $img  = $self->image($word);
	my $sha  = sha1_hex( $self->sanity( $word ) );
	$self->d("captcha($word)=$sha");
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

sub check {
	my $self = shift;
	local $!;
	my $s = $self->sanity( shift );
	my $hash = shift;
	my $w = sha1_hex($s);
	my ($w1,$w2,$rest) = split //,$w,3;
	if ($hash ne $w) {
		$self->d("Wrong hash: $w <=> $hash");
		return 0;
	};
	my $f = "$self->{temp}/$w1/$w2/$rest.png";
	my $r;
	if ( ! -e $f ){
		$self->d("($s) Non-existing file $f");
		return -1;
	}
	elsif (defined $self->{expire} and time - (stat($f))[9] > $self->{expire}) {
		$self->d("($s) Expired file $f");
		$r = -2; # expired
	}
	else {
		$self->d("($s) OK $f");
		$r = 1;
	}
	unlink $f or do {
		$self->d("($s) Can't delete used file $f: $!");
		$r = -1;
	};
	rmdir "$self->{temp}/$w1/$w2" and rmdir "$self->{temp}/$w1";
	return $r;
}

sub data {
	my $png = shift;
	my $w = shift;
	return unless $w =~ /^[\da-f]{40}$/;
	my ($w1,$w2,$rest) = split //,$w,3;
	open my $f, '<',"$TMP/$w1/$w2/$rest.png" or return;
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
				last SEARCH;
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
	$self->d("Found existing captcha `$found'");
	return $found;
}

sub make {
	my $self = shift;
	if ($self->{reuse} and my $ex = $self->get_old_unused()) {
		return $ex;
	} else {
		my ($w,$i) = $self->generate();
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
