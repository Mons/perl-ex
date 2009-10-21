#!/usr/bin/env perl

use uni::perl;
use lib::abs '../lib';
use Captcha::Easy;
use R::Dump;

my $ce = Captcha::Easy->new(
	temp => lib::abs::path('tmp'),
	#reuse => 0,
	#expire => 3,
);

my ($hash) = $ce->make;
warn Dump + $hash;
my $check = <>;
chomp $check;
warn Dump $ce->check( $check,$hash );


__END__
use constant pi => 3.141592;
sub transform;

sub rnd($$)  { $_[0] + rand() * ( $_[1] - $_[0] ); }
sub irnd($$) { int &rnd(@_); }
sub rot (@) { @_[1..$#_],$_[0] }

sub image {
	#my ($w,$h) = (200,70);
	my $word = shift;
	my ($w,$h) = (160,56);
	my $image  = Imager->new(xsize => $w, ysize => $h);
	my $font = Imager::Font->new(
		file => lib::abs::path('.').'/font.ttf',
		size => int($h/2),
	) or warn "no font";
	#my @bbox
	#my ($neg_width,$global_descent,$pos_width,$global_ascent,$descent,$ascent,$advance_width,$right_bearing)
	my $bbox
		= $font->bounding_box( string=> $word, canon => 1 );
	my $tw = $bbox->display_width;
	my $th = $bbox->text_height;
	#warn  "$tw x $th";
	my $bg = irnd (0,0x606060);my $fg = ( ~ $bg ) & 0xFFFFFF;
	$_ = Imager::Color->new(sprintf('#%06X',$_)) for $bg,$fg;
	$image->box(fill => Imager::Fill->new( solid => $bg ));
	$image->string(
		font => $font,
		color => $fg,
		x => int(($w - $tw)/2),
		y => int(($h - $th)/2) + $th,
		aa => 1,
		string => $word,
	) or warn "string: ".$image->errstr;
	my $img2 = transform($image,$fg,$bg);
	return $img2;
	for my $format ( qw( png gif jpeg tiff ppm ) ) {
		# Check if given format is supported
		if ($Imager::formats{$format}) {
			my $file = "captcha.$format";
			print "Storing image as: $file\n";
			# documented in Imager::Files
			$img2->write( file=>$file ) or
				die $image->errstr;
			last;
		}
	}
	return;
}

cmpthese timethese 100, {
	imager => sub { image('test') },
	imlib  => sub { Captcha::image('test') },
};
#image('test');
#Captcha::image('test');

exit;

sub transform {
	my ($src,$fg,$bg) = @_;
	my $image = $src->scale( scalefactor => 1.25 );
	#$image->filter( type => conv => coef => [ 1,2,1 ]) or die $image->errstr;
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
