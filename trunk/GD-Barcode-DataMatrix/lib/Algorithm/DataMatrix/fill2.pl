use strict;
use warnings;
use Test::More 'no_plan';
use Benchmark qw(:all);
use lib::abs '../..';
use Algorithm::DataMatrix::Fill;
use Data::Dumper;
our @FORMATS = (
	[10, 10, 8, 8, 1, 8, 8, 3, 5, 3, 5, 1],
	[12, 12, 10, 10, 1, 10, 10, 5, 7, 5, 7, 1],
	[14, 14, 12, 12, 1, 12, 12, 8, 10, 8, 10, 1],
	[16, 16, 14, 14, 1, 14, 14, 12, 12, 12, 12, 1],
	[18, 18, 16, 16, 1, 16, 16, 18, 14, 18, 14, 1],
	[20, 20, 18, 18, 1, 18, 18, 22, 18, 22, 18, 1],
	[22, 22, 20, 20, 1, 20, 20, 30, 20, 30, 20, 1],
	[24, 24, 22, 22, 1, 22, 22, 36, 24, 36, 24, 1],
	[26, 26, 24, 24, 1, 24, 24, 44, 28, 44, 28, 1],
	[32, 32, 14, 14, 4, 28, 28, 62, 36, 62, 36, 1],
	[36, 36, 16, 16, 4, 32, 32, 86, 42, 86, 42, 1],
	[40, 40, 18, 18, 4, 36, 36, 114, 48, 114, 48, 1],
	[44, 44, 20, 20, 4, 40, 40, 144, 56, 144, 56, 1],
	[48, 48, 22, 22, 4, 44, 44, 174, 68, 174, 68, 1],
	[52, 52, 24, 24, 4, 48, 48, 204, 84, 102, 42, 2],
	[64, 64, 14, 14, 16, 56, 56, 280, 112, 140, 56, 2],
	[72, 72, 16, 16, 16, 64, 64, 368, 144, 92, 36, 4],
	[80, 80, 18, 18, 16, 72, 72, 456, 192, 114, 48, 4],
	[88, 88, 20, 20, 16, 80, 80, 576, 224, 144, 56, 4],
	[96, 96, 22, 22, 16, 88, 88, 696, 272, 174, 68, 4],
	[104, 104, 24, 24, 16, 96, 96, 816, 336, 136, 56, 6],
	[120, 120, 18, 18, 36, 108, 108, 1050, 496, 175, 68, 6],
	[132, 132, 20, 20, 36, 120, 120, 1304, 496, 163, 62, 8],
	[144, 144, 22, 22, 36, 132, 132, 1558, 620, 156, 62, 10],
	[8, 18, 6, 16, 1, 6, 16, 5, 7, 5, 7, 1],
	[8, 32, 6, 14, 2, 6, 28, 10, 11, 10, 11, 1],
	[12, 26, 10, 24, 1, 10, 24, 16, 14, 16, 14, 1],
	[12, 36, 10, 16, 2, 10, 32, 22, 18, 22, 18, 1],
	[16, 36, 14, 16, 2, 14, 32, 32, 24, 32, 24, 1],
	[16, 48, 14, 22, 2, 14, 44, 49, 28, 49, 28, 1],
);

use GD::Barcode::DataMatrix::Engine;
sub rs($$){ GD::Barcode::DataMatrix::Engine::CalcReed(@_); }

my $self;
for my $f (@FORMATS[1]) {
	@$self{qw(
		rows      
		cols      
		datarows  
		datacols  
		regions   
		maprows   
		mapcols   
		totaldata 
		totalerr  
		reeddata  
		reederr   
		reedblocks
	)} = @$f;
	warn Dumper $f;
	#my $ai = rs([202,251,226,117,201],7);# 5/7
	my $ai = [202,251,226,117,201,212,248,83,197,212,118,194];

	my $ai2 = [];
	my $ai1 = [];#Algorithm::DataMatrix::Fill::borders(@$f[0,1,4,2,3]);
	print join("\n",map { join ('', map { defined $_ ? $_ : '-' } @{$_}) } @{ $ai1 } ),"\n";
	#last;
	my $x = Algorithm::DataMatrix::Fill->new(@$f[5,6],$ai2);
	print join ", ",@$ai2,"\n";
	my $x = Algorithm::DataMatrix::Fill->new(@$f[5,6],$ai2);
	print join ", ",@$ai2,"\n";
	print "\033[s";
	for(my $i2 = 0; $i2 < $self->{maprows}; $i2++) {
        my $j2 = 1;
        for(my $k2 = 0; $k2 < $self->{mapcols}; $k2++) {
        }
    }
	last;
    my $j1 = 1;
    my $flag = 0;
    my $flag1 = 0;
	for(my $i2 = 0; $i2 < $self->{maprows}; $i2++) {
        my $j2 = 1;
        for(my $k2 = 0; $k2 < $self->{mapcols}; $k2++) {
            my $l1 = $k2 + $j2;
            my $k1 = $i2 + $j1;
            if($ai2->[$i2 * $self->{mapcols} + $k2] > 9) {
            	my $l2 = int ( $ai2->[$i2 * $self->{mapcols} + $k2] / 10 );
            	my $i3 = $ai2->[$i2 * $self->{mapcols} + $k2] % 10;
                my $j3 = $ai->[$l2 - 1] & 1 << 8 - $i3;
                $ai1->[$l1][$k1] = $j3 ? 1 : 0;
            } else {
            	$ai1->[$l1][$k1] = $ai2->[$i2 * $self->{mapcols} + $k2] ? 1 : 0;
            }
        	if($k2 > 0 && ($k2 + 1) % $self->{datacols} == 0) {
                $j2 += 2;
            }
        }

    	if($i2 > 0 && ($i2 + 1) % $self->{datarows} == 0) {
            $j1 += 2;
        }
    }
	#$x->fill;
	#print Dumper $ai1;
	print join("\n",map { join ('', map { defined $_ ? $_ : '-' } @{$_||[]}) || '--' } @{ $ai1 } ),"\n";
	last;
}
sub b5 {
	use integer;
	my ($w,$h,$regions,$dc,$dr) = @_;
	my @matrix;
	#warn "width = $w, height = $h, datacols = $dc, datarows = $dr, reg = $regions";
	$dc += 2;
	$dr += 2;
	if ($regions == 2) {
		for (0..1) {
			my $rt = $_ * $dr;
			my $rb = ($_+1) * $dr - 1;
			for (0..$w-1) {
				$matrix[$rt][$_] = 1;
				$matrix[$rb][$_] = $_ & 1;
			}
		}
		{
			my $cr = $dc - 1;
			for (0..$h-1) {
				$matrix[$_][$cr] = 1;
				$matrix[$_][0] = ($_ & 1) ? 0 : 1;
			}
		}
	} else {
		my $k = sqrt $regions;
		for (0..$k-1) {
			{
				my $rt = $_ * $dr;
				my $rb = ($_+1) * $dr - 1;
				for (0..$w-1) {
					$matrix[$rt][$_] = 1;
					$matrix[$rb][$_] = $_ & 1;
				}
			}
			{
				my $cl = $_ * $dc;
				my $cr = ($_+1) * $dc - 1;
				for (0..$h-1) {
					$matrix[$_][$cr] = 1;
					$matrix[$_][$cl] = ($_ & 1) ? 0 : 1;
				}
			}
		}
	}
	return \@matrix;
}

__END__
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ orig()}),"\n";
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ borders(@$f[4,3,2])}),"\n";
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ b5(@$f[0,1,4,2,3])}),"\n";
    #next;
    cmpthese timethese 100 => {
    	#old => sub { orig() },
    	#new => sub { borders(@$f[4,3,2]) },
    	#b3  => sub { b3(@$f[0,1,4,3,2]) },
    	b4  => sub { b4(@$f[0,1,4,3,2]) },
    	b5  => sub { b5(@$f[0,1,4,2,3]) },
    };
    last;
	is_deeply(orig(),b5(@$f[0,1,4,2,3]), "$$f[0]x$$f[1]");
}


__END__
my $i = 3;
if (0){{use integer;
	for (0..9) {
		print $_ & 1;
	}
	print "\n";
	for (0..9) {
		print 1&$_^1;
	}
	print "\n";
    cmpthese timethese -1 => {
    	div => sub { $i % 2 },
    	bit1 => sub { $i & 1 },
    	bit2 => sub { 1 ^ $i & 1 },
    };exit;
	exit;
}}
our @FORMATS = (
	[10, 10, 8, 8, 1, 8, 8, 3, 5, 3, 5, 1],
	[12, 12, 10, 10, 1, 10, 10, 5, 7, 5, 7, 1],
	[14, 14, 12, 12, 1, 12, 12, 8, 10, 8, 10, 1],
	[16, 16, 14, 14, 1, 14, 14, 12, 12, 12, 12, 1],
	[18, 18, 16, 16, 1, 16, 16, 18, 14, 18, 14, 1],
	[20, 20, 18, 18, 1, 18, 18, 22, 18, 22, 18, 1],
	[22, 22, 20, 20, 1, 20, 20, 30, 20, 30, 20, 1],
	[24, 24, 22, 22, 1, 22, 22, 36, 24, 36, 24, 1],
	[26, 26, 24, 24, 1, 24, 24, 44, 28, 44, 28, 1],
	[32, 32, 14, 14, 4, 28, 28, 62, 36, 62, 36, 1],
	[36, 36, 16, 16, 4, 32, 32, 86, 42, 86, 42, 1],
	[40, 40, 18, 18, 4, 36, 36, 114, 48, 114, 48, 1],
	[44, 44, 20, 20, 4, 40, 40, 144, 56, 144, 56, 1],
	[48, 48, 22, 22, 4, 44, 44, 174, 68, 174, 68, 1],
	[52, 52, 24, 24, 4, 48, 48, 204, 84, 102, 42, 2],
	[64, 64, 14, 14, 16, 56, 56, 280, 112, 140, 56, 2],
	[72, 72, 16, 16, 16, 64, 64, 368, 144, 92, 36, 4],
	[80, 80, 18, 18, 16, 72, 72, 456, 192, 114, 48, 4],
	[88, 88, 20, 20, 16, 80, 80, 576, 224, 144, 56, 4],
	[96, 96, 22, 22, 16, 88, 88, 696, 272, 174, 68, 4],
	[104, 104, 24, 24, 16, 96, 96, 816, 336, 136, 56, 6],
	[120, 120, 18, 18, 36, 108, 108, 1050, 496, 175, 68, 6],
	[132, 132, 20, 20, 36, 120, 120, 1304, 496, 163, 62, 8],
	[144, 144, 22, 22, 36, 132, 132, 1558, 620, 156, 62, 10],
	[8, 18, 6, 16, 1, 6, 16, 5, 7, 5, 7, 1],
	[8, 32, 6, 14, 2, 6, 28, 10, 11, 10, 11, 1],
	[12, 26, 10, 24, 1, 10, 24, 16, 14, 16, 14, 1],
	[12, 36, 10, 16, 2, 10, 32, 22, 18, 22, 18, 1],
	[16, 36, 14, 16, 2, 14, 32, 32, 24, 32, 24, 1],
	[16, 48, 14, 22, 2, 14, 44, 49, 28, 49, 28, 1],
);
*FillBorder = \&border;
#*FillBorder = \&FillBorder1;

my $self;
for my $f (@FORMATS[23]) {
	$self = {};
	@$self{qw(
		rows      
		cols      
		datarows  
		datacols  
		regions   
	)} = @$f;
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ orig()}),"\n";
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ borders(@$f[4,3,2])}),"\n";
    #print join("\n",map { join ('', map { defined $_ ? $_ : ' ' } @$_) }@{ b5(@$f[0,1,4,2,3])}),"\n";
    #next;
    cmpthese timethese 100 => {
    	#old => sub { orig() },
    	#new => sub { borders(@$f[4,3,2]) },
    	#b3  => sub { b3(@$f[0,1,4,3,2]) },
    	b4  => sub { b4(@$f[0,1,4,3,2]) },
    	b5  => sub { b5(@$f[0,1,4,2,3]) },
    };
    last;
	is_deeply(orig(),b5(@$f[0,1,4,2,3]), "$$f[0]x$$f[1]");
}

sub b5 {
	use integer;
	my ($w,$h,$regions,$dc,$dr) = @_;
	my @matrix;
	#warn "width = $w, height = $h, datacols = $dc, datarows = $dr, reg = $regions";
	$dc += 2;
	$dr += 2;
	if ($regions == 2) {
		for (0..1) {
			my $rt = $_ * $dr;
			my $rb = ($_+1) * $dr - 1;
			for (0..$w-1) {
				$matrix[$rt][$_] = 1;
				$matrix[$rb][$_] = $_ & 1;
			}
		}
		{
			my $cr = $dc - 1;
			for (0..$h-1) {
				$matrix[$_][$cr] = 1;
				$matrix[$_][0] = ($_ & 1) ? 0 : 1;
			}
		}
	} else {
		my $k = sqrt $regions;
		for (0..$k-1) {
			{
				my $rt = $_ * $dr;
				my $rb = ($_+1) * $dr - 1;
				for (0..$w-1) {
					$matrix[$rt][$_] = 1;
					$matrix[$rb][$_] = $_ & 1;
				}
			}
			{
				my $cl = $_ * $dc;
				my $cr = ($_+1) * $dc - 1;
				for (0..$h-1) {
					$matrix[$_][$cr] = 1;
					$matrix[$_][$cl] = ($_ & 1) ? 0 : 1;
				}
			}
		}
	}
	return \@matrix;
}

sub b4 {
	use integer;
	my ($w,$h,$regions,$dc,$dr) = @_;
	my @matrix;
	#$_+=2 for $dc,$dr;
	$dc += 2;
	$dr += 2;
	#my @matrix = map {[]} 0..$h-1;
	#@{$matrix[0]} = (1)x$dr;
	my $k = sqrt $regions;
	for my $x (0..$k-1) {
		{
			my $rt = $x * $dr;
			my $rb = ($x+1) * $dr - 1;
			for (0..$h-1) {
				$matrix[$rt][$_] = 1;
				$matrix[$rb][$_] = $_%2;
			}
		}
		{
			my $cl = $x * $dc;
			my $cr = ($x+1) * $dc - 1;
			for (0..$w-1) {
				$matrix[$_][$cr] = 1;
				$matrix[$_][$cl] =int !( $_%2 );
			}
		}
	}
	return \@matrix;
}

sub b3 {
	use integer;
	my ($w,$h,$regions,$dc,$dr) = @_;
	$_+=2 for $dc,$dr;
	my @matrix = map {[]} 0..$h-1;
	#@{$matrix[0]} = (1)x$dr;
	my $k = sqrt $regions;
	for my $x (0..$k-1) {
		my $rt = $x * $dr;
		my $rb = ($x+1) * $dr - 1;
		for my $c (0..$h-1) {
			$matrix[$rt][$c] = 1;
			$matrix[$rb][$c] = $c%2;
		}
	}
	for my $x (0..$k-1) {
		my $cl = $x * $dc;
		my $cr = ($x+1) * $dc - 1;
		for my $r (0..$w-1) {
			$matrix[$r][$cr] = 1;
			$matrix[$r][$cl] =int !( $r%2 );
		}
	}
	#for my $rc (0..$k-1) { for my $c (0..$h-1) {
	#	my $r = ($rc+1) * $dr;
	#	$matrix[$r][$c] = $c%2;
	#}}
=for rem
	for my $r (0..$w-1) {for my $c (0..$h-1) {
		if ( !( $r%$dr ) ) { # top borders
			$matrix[$r][$c] = 1;
		}
		if ( !( ($r+1)%$dr ) ) { # bottom borders
			$matrix[$r][$c] = $c%2;
		}
		if ( !( $c%$dc ) ) { # left borders
			$matrix[$r][$c] = int !($r%2);
		}
		if ( !( ($c+1)%$dc ) ) { # right borders
			$matrix[$r][$c] = 1;
		}
	}}
=cut
	return \@matrix;
}

sub borders {
	use integer;
	my ($regions,$dc,$dr) = @_;
	$_+=2 for $dc,$dr;
	my @matrix;
	if($regions == 2) {
		border(\@matrix, 0, 0, $dc, $dr);
		border(\@matrix, $dc, 0, $dc, $dr);
	} else {
		my $k = sqrt $regions;
		for my $x (0..$k-1){
			for my $y (0..$k-1) {
				border(\@matrix, $x * $dc, $y * $dc, $dc, $dr );
			}
		}
	}
	return \@matrix;
}

sub border {
	use integer;
	my ($a,$r,$c,$h,$w) = @_;
	# vertical
	for (0..$h-1) {
		$a->[$r+$_][ $c + $w - 1 ] = 1;
		$a->[$r+$_][ $c ] = int !($_ % 2);
	}
	# horisontal
	for(0 .. $w-1) {
		$a->[$r][$c + $_] = 1;
		$a->[$r+$h-1][$c + $_] = $_%2;
	}
}

sub orig {
	my $ai1 = [ map { [ (undef) x $self->{rows} ] } 1..$self->{cols} ]; # reverse cols/rows here, for correct access ->[][]
	
    my $i = my $j = 0;
    # Draw border
    if($self->{regions} == 2) {
		FillBorder($ai1, $i, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    	FillBorder($ai1, $i + $self->{datacols} + 2, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    } else {
    	my $k = int(sqrt($self->{regions}));
        for (my $l = 0; $l < $k; $l++){
            for(my $i1 = 0; $i1 < $k; $i1++) {
            	local $, = " ";
            	print "Fill ",$i + $l * ($self->{datacols} + 2), $j
            			+ $i1 * ($self->{datarows} + 2),
            		$self->{datacols} + 2, $self->{datarows} + 2,"\n" if 0;

            	FillBorder($ai1, $i + $l * ($self->{datacols} + 2), $j
            		+ $i1 * ($self->{datarows} + 2),
            		$self->{datacols} + 2, $self->{datarows} + 2);
				#last;
			}
			#last;
        }

    }
    return $ai1;
}

sub FillBorder1 { # CD (int ai[][], int i, int j, int k, int l) : void
	my ($ai,$i,$j,$k,$l) = @_;
	#warn "[CD] FillBorder([".join(",",@$ai)."],$i,$j,$k,$l)\n";
    my $i1 = 0;
    for(my $k1 = 0; $k1 < $k; $k1++) {
        $i1 = ($k1 % 2 == 0) ? 1 : 0;
        $ai->[$i + $k1][$j + $l - 1] = 1;
        $ai->[$i + $k1][$j] = $i1;
    }
    $i1 = 0;
    for(my $l1 = 0; $l1 < $l; $l1++) {
        my $j1 = (($l1 + 1) % 2 == 0) ? 1 : 0;
        $ai->[$i][$j + $l1] = 1;
        $ai->[$i + $k - 1][$j + $l1] = $j1;
    }
}

