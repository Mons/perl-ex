package GD::Barcode::DataMatrix;

use strict;
use warnings;

use GD ();
use GD::Barcode::DataMatrix::Engine ();
use base qw(GD::Barcode);

our $VERSION = 0.01;
our $errStr;
#------------------------------------------------------------------------------
# new (for GD::Barcode::DataMatrix)
#------------------------------------------------------------------------------
sub new {
	my($cls, $txt, %params) = @_;
	$errStr ='';
	my $self = bless{},$cls;
	return undef if($errStr = $self->init($txt,%params));
	return $self;
}
#------------------------------------------------------------------------------
# init (for GD::Barcode::DataMatrix)
#------------------------------------------------------------------------------
sub init {
	my($self, $txt,%params) =@_;
	return 'Text required' if $txt eq '';
	$self->{text} = $txt;
	$self->{Type} = $params{Type} || 'AUTO';
	$self->{ngn} = eval {
		my $type = $params{Type} || undef;
		my $pt = $params{ProcessTilde} || undef;
		my $sz = $params{Size} || undef;
		GD::Barcode::DataMatrix::Engine->new($txt,$type,$sz,$pt);
	};
	return "Error: $@" unless $self->{ngn};
	return '';
}
#------------------------------------------------------------------------------
# new (for GD::Barcode::DataMatrix)
#------------------------------------------------------------------------------
sub barcode {
    my $self = shift;
	my (%params) = @_;
	my %dr = (
		1 => $params{1} || '1',
		0 => $params{0} || '0',
	);
	my $rc = '';# $self->{Type}."\n";
	my $a = [];
	@$self{qw(rows cols)} = @{$self->{ngn}}{qw(rows cols)};
	for my $r (0..$self->{rows}-1){
		my $aa = [];
		for my $c (0..$self->{cols}-1){
			my $d = ( $self->{ngn}->{bitmap}[$c][$r] ? 1 : 0 );
			push @$aa,$d;
			$rc .= $dr{$d};
		}
		push @$a, $aa;
		$rc .= "\n";
	}
	$self->{grid} = $a;
    return $rc;
}

#------------------------------------------------------------------------------
# plot (for GD::Barcode::DataMatrix)
#------------------------------------------------------------------------------
sub plot($;%) {
	my $self = shift;
	my (%params) = @_;
	$self->barcode();
	my ($marginLeft,$marginRight,$marginTop,$marginBottom) = (4,4,4,4);
	my ($w,$h);
	my $oOutImg = GD::Image->new(
		$h = ($self->{rows} + $marginTop + $marginBottom),
		$w = ($self->{cols} + $marginLeft + $marginRight),
	);
    
    my $cWhite = $oOutImg->colorAllocate(255, 255,255); #For BackColor
    my $cBlack = $oOutImg->colorAllocate(  0,   0,  0);
	
	for my $x ( 0 .. $self->{cols} ) {
		for my $y ( 0 .. $self->{rows} ) {
			if ($self->{grid}[$y][$x]){
				$oOutImg->setPixel($x + $marginLeft, $y + $marginTop, $cBlack);
			}
		}
	}
	if (my $factor = $params{Scale}) {
		my $oNewImg =  GD::Image->new($w * $factor,$h*$factor);
		$oNewImg->copyResized($oOutImg,0,0,0,0,$w * $factor,$h*$factor,$w,$h);
		$oOutImg = $oNewImg;
	}
	return $oOutImg;
}
1;
__END__



=head1 NAME

GD::Barcode::DataMatrix - Create ISO/IEC16022 DataMatrix barcode

=head1 SYNOPSIS

I<ex. CGI>

  use GD::Barcode::DataMatrix;
  binmode(STDOUT);
  print "Content-Type: image/png\n\n";
  print GD::Barcode::DataMatrix->new('1234567890')->plot->png;

I<with Error Check>

  my $oGdBar = GD::Barcode::DataMatrix->new('A12345678');
  die $GD::Barcode::DataMatrix::errStr unless($oGdBar);     #Invalid Characters
  $oGdBar->plot->png;


=head1 DESCRIPTION

GD::Barcode::DataMatrix is a subclass of GD::Barcode and allows you to
create DataMatrix barcode image with GD.

=head2 new

I<$oGdBar> = GD::Barcode::DataMatrix->new(I<$sTxt>, [ Type => I<ASCII | C40 | TEXT | BASE256 | NONE | AUTO>, Size => "${width}x${height}", Tilde => I<0 | 1>]);

Constructor. 
Creates a GD::Barcode::DataMatrix object for I<$sTxt>.

=head2 plot()

I<$oGd> = $oGdBar->plot([Height => I<$iHeight>, NoText => I<0 | 1>]);

creates GD object with barcode image for the I<$sTxt> specified at L<new> method.
I<$iHeight> is height of the image. If I<NoText> is 1, the image has no text image of I<$sTxt>.

 ex.
  my $oGdB = GD::Barcode::DataMatrix->new('12345678');
  my $oGD = $oGdB->plot(NoText=>1, Height => 20);
  # $sGD is a GD image with Height=>20 pixels, with no text.

=head2 barcode()

I<$sPtn> = $oGdBar->barcode();

returns a barcode pattern in string with '1' and '0'. 
'1' means black, '0' means white.

 ex.
  my $oGdB = GD::Barcode::DataMatrix->new('12345678');
  my $sPtn = $oGdB->barcode();

=head2 $errStr

$GD::Barcode::DataMatrix::errStr

has error message.

=head2 $text

$oGdBar->{$text}

has barcode text based on I<$sTxt> specified in L<new> method.

=head1 SEE ALSO

=over 4

=item * L<GD::Barcode>

=back

=head1 AUTHOR

Mons Anderson <inthrax@gmail.com>

=head1 COPYRIGHT

The GD::Barocde::DataMatrix module is Copyright (c) 2008-2009 Mons Anderson.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut