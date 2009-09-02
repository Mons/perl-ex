package GD::Barcode::DataMatrix::Engine;

use strict;
no warnings qw(uninitialized);
use GD::Barcode::DataMatrix::Constants ();
use GD::Barcode::DataMatrix::CharDataFiller ();
use Data::Dumper;
use constant DEBUG => 1;

our %DEBUG = (
	ENC    => 1,
	CALC   => 0,
	TRACE  => 1,
	B256   => 0
);

our @GFI     = GD::Barcode::DataMatrix::Constants::GFI();
our @GFL     = GD::Barcode::DataMatrix::Constants::GFL();
our %POLY    = GD::Barcode::DataMatrix::Constants::POLY();
our $FORMATS = GD::Barcode::DataMatrix::Constants::FORMATS();
our $C1      = GD::Barcode::DataMatrix::Constants::C1();

sub E_ASCII  () { 0 }
sub E_C40    () { 1 }
sub E_TEXT   () { 2 }
sub E_BASE256() { 3 }
sub E_NONE   () { 4 }
sub E_AUTO   () { 5 }

our $N = 255;

sub Types {
	return qw( ASCII C40 TEXT BASE256 NONE AUTO );
}

sub stringToType($) {
	my $m = 'E_'.shift;
	return  eval { __PACKAGE__->$m(); };
}
sub typeToString($) {
	my $i = shift;
	for (Types) {
		return $_ if stringToType($_) == $i and defined $i;
	}
	return 'UNK';
}

sub stringToFormat($) {
	my $sz = shift;
	return unless $sz;
	my ($w,$h) = map { +int } split /\s*x\s*/,$sz,2;
	my $r;
	for my $i (0..$#$FORMATS) {
		$r = $i,last if $FORMATS->[$i][0] == $w and $FORMATS->[$i][1] == $h;
	}
	die "Format not supported ($sz)\n" unless defined $r;
	return $r;
}

sub setType {
	my $self = shift;
	my $type = shift;
	my $t = stringToType($type);
	warn "setType $type => $t\n" if $DEBUG{ENC};
	#$t = E_AUTO unless defined $t;
	$t = E_ASCII unless defined $t;
	$self->{encoding} = $self->{currentEncoding} = $t;
	warn "Have type $t (".typeToString($t).")\n" if $DEBUG{ENC};
	return;
}

sub new {
	my $self = bless{},shift;
	$self->init();
	warn "[CA] new(@_)\n" if $DEBUG{TRACE};
	$self->{orig} = $self->{code} = shift;  # text
	$self->setType(shift); # type of code
	$self->{preferredFormat} = stringToFormat(shift) || -1; # type of format
	$self->{as} = [  ];
	$self->ProcessTilde if (shift);         # process tilde ???
	return unless ( my $l = length($self->{code}) );        # no data to encode
    $self->{ac} = [ split //,$self->{code} ]; # create an char array
	$self->{ai} = [ map { +ord } @{ $self->{ac} } ]; # create an int array
	$self->CreateBitmap();
	return $self;
}

sub init {
	my $self = shift;
	my %p = (
        processTilde            => 0,#0
        encoding                => E_ASCII,
        preferredFormat         => -1,
        currentEncoding         => E_ASCII,
        C49rest                 => 0,
	);
	for (keys %p){
		$self->{$_} = $p{$_};
	}
}

sub ProcessTilde {
	my $self = shift;
	my $s = $self->{code};
	my $as = $self->{as};
	for ($s) {
		s{~d(\d{3})}{ chr($1) }ge;
		s{~d.{3}}{}g;
		s{~1}{\350}g;
		#s{^~2}{ \350 };
		s{^~3}{\352};
		s{^~([56])}{ chr(231+$1) }e;
		my $ofs = -1;
		#while ((my $o = index( $_, '~7' )) > $ofs) {
			
			s{~7(.{6})}{do{
				my $d = int $1;
				warn "There is $d got from $1\n";
				if ($d < 127) {
					$d = chr($d+1);
				}
				elsif($d < 16383) {
					$d =
						chr( ( $d - 127 ) / 254 + 128 ).
						chr( ( $d - 127 ) % 254 + 1 );
				}
				else{
					$d =
						chr( int+ ( $d - 16383 ) / 64516 + 192 ).
						chr( int( ( $d - 16383 ) / 254 ) % 254 + 1 ).
						chr( int+ ( $d - 16383 ) % 254 + 1 );
				}
				$as->[$-[0]] = $d;
				warn "PT affect as[$-[0]] = ".join('+', map ord, split //, $d);
				"\361"
			}}ge;
		#}
		s{~}{}g;
		
		warn "[C9] ProcessTilde($self->{code}) => $_\n" if $DEBUG{TRACE};
		return $self->{code} = $_;
	}
    my $flag = 0;
    my $k = length($s);
    
    my $s1 = "";
    my $flag1 = 0;
    for (my $i = 0; $i < $k; $i++) {
    	my $j = ord(substr($s,$i,1)); #char code at $i
        if($j == 126) {
            if($i < $k - 1) {
        		my $c = substr($s,$i+1,1);
                if($c ge '@' && $c le 'Z') {
                    $i++;
                    $s1 .= chr(ord($c) - 64);
                }
                if( $c eq '~' ) {
                    $s1 .= '~';
                    $i++;
                }
                if( $c eq '1' ) {
                    if(length($s1) =~ /^(0|1|4|5)$/) {
                        $as->[length($s1)] = "";
                        $s1 = $s1 . chr(oct(350));
                    } else {
                        $s1 = $s1 . chr(oct(35));
                    }
                    $i++;
                }
                if( $c eq '2' and $i < $k - 4) {
                    $as->[length($s1)] = substr($s,$i+2,3);
                    $s1 .= chr(oct(351));
                    $i += 4;
                }
                if( $c =~ /^(3|5|6)$/ and length($s1) == 0 ) {
                    $as->[0] = "";
                    $s1 .= chr(oct(349+$c));
                    $i++;
                }
                if( $c eq '7' and $i < $k - 7) {
                    my $s2 = substr($s,$i+2,$i+8);
                    my $d = 0.0 + $s2;
                    if($d <= 126) {
                        $as->[ length($s1) ] = "" . chr(int($d + 1.0));
                        $s1 .= chr(oct(361));
                    }
                    if($d >= 127 && $d <= 16382) {
                        my $i1 = int(($d - 127) / 254) + 128;
                        my $k1 = int(($d - 127) % 254) + 1;
                        $as->[length($s1)] = chr($i1) . chr($k1);
                        $s1 .= chr(oct(361));
                    }
                    if($d >= 16383) {
                        my $j1 = int(($d - 16383) / 64516) + 192;
                        my $l1 = int(($d - 16383) / 254);
                        $l1 = $l1 % 254 + 1;
                        my $i2 = int(($d - 16383) % 254) + 1;
                        $as->[length($s1)] = chr($j1) . chr($l1) . chr($i2);
                        $s1 .=  chr(oct(361));
                    }
                    $i += 7;
                }
                if($c eq 'd' and $i < $k - 3) {
                    my $s3 = substr($s,$i+2,$i+5);
                    my $l = 0 + $s3;
                    $l = 255 if $l > 255;
                    $s1 .= chr($l);
                    $i += 4;
                }
            }
        } else {
            $s1 .= chr($j);
        }
    }
	warn "[C9] ProcessTilde($s) => $s1\n" if $DEBUG{TRACE};
    $self->{code} = $s1;
}

sub CalcReed { # (int ai[], int i, int j) : void
	sub getpoly($) { # (int i) : void
		my $i = shift;
		return exists $POLY{$i} ? $POLY{$i} : $POLY{68};
	}
	sub mult($$) { # (int i, int j) : int
		my ($i,$j) = @_;
		my $k = 0;
		return 0 unless 1* $i * $j;
		$k = $GFL[$i] + $GFL[$j];
		$k -= $N if $k >= $N;
		return $GFI[$k];
	}
	sub short($) {
		my $s = shift;
		return $s & 0xFF;
	}
		
	my ($ai,$i,$j) = @_;
	warn "CalcReed(ai {".join(" ",grep{+defined}@$ai)."},$i,$j)\n" if $DEBUG{CALC};
	my $p = getpoly($j);
	warn "CalcReed: poly {".join(" ",@$p)."}\n" if $DEBUG{CALC};
    @$ai[ $i .. $i + $j - 1 ] = (0) x $j;
    for my $l(0 .. $i - 1) {
        my $word0 = short($ai->[$i] ^ $ai->[$l]);
        for my $i1 (0 .. $j - 1) {
            $ai->[$i + $i1] = short( $ai->[$i + $i1 + 1] ^ mult($word0, $p->[$i1]) );
        }
        $ai->[$i+$j-1] = mult($word0, $p->[$j - 1]);
    }
}

sub CreateBitmap() #CB (int ai[], String as[]) : int[][]
{
	my $self = shift;
	my ($ai,$as) = @$self{qw(ai as)};
	warn "[CB] CreateBitmap(ai[" .join(',',@$ai).'], as[' . scalar(@$as) .  "])\n" if $DEBUG{TRACE};
    my $ai1 = [];
    my $ai2 = [ 0 ];
    my $ai3 = [ 0 ];
    my $i = 0;
	$self->{currentEncoding} = $self->{encoding} if $self->{encoding} != E_AUTO;
	#warn "AI Before enc: ".join(" ",@$ai)."\n";
	for ($self->{encoding}){
		warn "[CB] Select method for $self->{encoding}, ".typeToString($self->{encoding})."\n" if $DEBUG{ENC};
		$_ == E_AUTO    && do { $i = $self->DetectEncoding($ai1); last;};
		$_ == E_ASCII   && do { $i = $self->DetectASCII(scalar(@$ai), $ai, $ai1, $as); last;};
		$_ == E_C40     && do { $i = $self->Check6(scalar(@$ai), $ai2, $ai, $ai1, 0, 1, 0); last;};
		$_ == E_TEXT    && do { $i = $self->Check6(scalar(@$ai), $ai2, $ai, $ai1, 1, 1, 0); last;};
		$_ == E_BASE256 && do { $i = $self->CheckBase256(scalar(@$ai), $ai2, $ai, $ai3, $ai1, 0, $as); last;};
		$_ == E_NONE    && do {
	        for my $j (0 .. ( $i = $#$ai )) {
	        	$ai1->[$j] = $ai->[$j];
	    	}
	    	$i++;
			last;
		};
		
	}
	DEBUG and print "Use Encoding: " .typeToString($self->{currentEncoding}). "(".typeToString($self->{encoding}).")\n";
	#warn "AI1 After enc: ".join(" ",@$ai1)."\n";
	warn "[CB]: enc res: ".typeToString($self->{encoding}).", " .typeToString($self->{currentEncoding}). "\n" if $DEBUG{ENC};
    my $k = 0;
	if($self->{preferredFormat} != -1) {
    	$k = $self->{preferredFormat};
        $k = 0 if $i > $FORMATS->[$k][7];
    }
	#warn "[CB]: format: $k\n";
    for(; $i > $FORMATS->[$k][7] && $k < 30; $k++)
    {
    	next if $self->{currentEncoding} != E_C40 && $self->{currentEncoding} != E_TEXT;
    	#warn "[CB]: enc: E_C40/E_TEXT\n";
        if($self->{C49rest} == 1 && $ai1->[$i - 2] == 254 && $FORMATS->[$k][7] == $i - 1) {
            $ai1->[$i - 2] = $ai1->[$i - 1];
            $ai1->[$i - 1] = 0;
            $i--;
            last;
        }
    	next if($self->{C49rest} != 0 || $ai1->[$i - 1] != 254 || $FORMATS->[$k][7] != $i - 1);
        $ai1->[$i - 1] = 0;
        $i--;
        last;
    }

    return if $k == 30;
    my $l = $k;
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
	)} = @{$FORMATS->[$l]}[0..11];
	DEBUG and print "Format: $self->{rows}x$self->{cols}; Data: $self->{totaldata}; i=$i\n";
	#warn "[CB]: Selected $self->{rows}x$self->{cols} [$self->{totaldata}]; $i\n";
	$ai1->[$i - 1] = 129 if (
		($self->{currentEncoding} == E_C40 || $self->{currentEncoding} == E_TEXT )
		and
		$self->{C49rest} == 0 && $i == $self->{totaldata} && $ai1->[$i - 1] == 254
    );
    my $ai4 = [];
    my $flag = 1;
	for(my $i1 = $i; $i1 < $self->{totaldata}; $i1++) {
		#warn "   CB: $i <= $i1 < $self->{totaldata}\n";
        $ai1->[$i1] = $flag ? 129 : A253(129, $i1 + 1);
        $flag = 0;
    }
	#warn "[CB]: ".Dumper($ai1);
    my $j1 = my $k1 = 0;
    for(my $l1 = 1; $l1 <= $self->{totaldata}; $l1++) {
        $ai4->[$j1][$k1] = $ai1->[$l1 - 1];
		#warn "\$a->[$j1][$k1] = $ai1->[$l1 - 1];\n";
        if(++$j1 == $self->{reedblocks}) {
            $j1 = 0;
            $k1++;
        }
    }
	#warn "***[CB]*** AI1 = {".join(" ",@{ $ai1 }[0 .. $self->{totaldata} ])."}\n";
	#warn "***[CB]*** AI4[0] = {".join(" ",@{ $ai4->[0] })."}\n";
	#warn "***[CB]*** AI4[1] = {".join(" ",@{ $ai4->[1] })."}\n";
    my $ai5 = [ ];
    my $i2 = 0;
	for(my $j2 = 0; $j2 < $self->{reedblocks}; $j2++) {
		$ai5->[$j2] = $self->{reeddata} + $self->{reederr};
    	my $k2 = $self->{reeddata};
        if($self->{rows} == 144 && $j2 > 7) {
    		$ai5->[$j2] = $self->{reeddata} + $self->{reederr} - 1;
            $k2 = 155;
        }
	#warn "[CB] ($k2, $self->{reederr}) ai4[$j2]{".join(",",grep { +defined } @{ $ai4->[$j2] })."}\n";
    	CalcReed($ai4->[$j2], $k2, $self->{reederr});
	#warn "[CB] ai4[$j2]{".join(",",grep { +defined } @{ $ai4->[$j2] })."}\n";
        $i2 += $ai5->[$j2];
    }
    my $ai6 = [ (undef) x $i2 ];
    my $l2 = my $i3 = 0;
    for(my $j3 = 0; $j3 < $ai5->[0]; $j3++) {
    	for(my $k3 = 0; $k3 < $self->{reedblocks}; $k3++){
    		#warn sprintf "$j3:$k3 => %s\n",$j3 < $ai5->[$k3] ? $ai4->[$k3][$j3] : "-";
            if($j3 < $ai5->[$k3]) {
                $ai6->[$i3++] = $ai4->[$k3][$j3];
                $l2++;
            }
		}
    }
    #warn "ai6{".join(",",@{ $ai6 }[0..40])."}\n";
	$self->{bitmap} = $self->GenData($ai6);
}

sub isCDigit { # C1*
	return shift =~ /^[0-9]$/ ? 1 : 0;
}
sub isIDigit { # C1
	my $i = shift;
	return ( $i >= 48 && $i <= 57 ) ? 1 : 0;
}
sub isILower {
	my $i = shift;
	return ( $i >= ord('a') && $i <= ord('z') ) ? 1 : 0;
}
sub isIUpper {
	my $i = shift;
	return ( $i >= ord('A') && $i <= ord('Z') ) ? 1 : 0;
}

sub DetectEncoding() #C4 (int i, int ai[], int ai1[], String as[]) : int
{
	my $self = shift;
	warn "[C4] DetectEncoding(@_)\n" if $DEBUG{TRACE};
	my $ai = $self->{ai};
	my $i = scalar (@$ai);
	my $as = $self->{as};
	my $ai1 = shift;
    my $ai2 = [  ];
    my $ai3 = [  ];
    my $flag = 0;
    my $j1 = 0;
    my $k1 = E_ASCII;
    my $ai4 = [ undef ];
    my $ai5 = [ undef ];
    my $l2 = E_ASCII;
    my $as1 = [  ];
    my $iterator = 0;
	$self->{currentEncoding} = E_ASCII;
    while($iterator < $i) { # while iterator less than length of data
    	while($self->{currentEncoding} == E_ASCII && $iterator < $i) {
            my $flag1 = 0;
            if(
            	$iterator + 1 < $i 
            	and isIDigit($ai->[$iterator])
            	and isIDigit($ai->[$iterator + 1])
            ){
                $ai1->[$j1++] = 254 if($l2 != E_ASCII);
                $ai2->[0]     = $ai->[$iterator];
                $ai2->[1]     = $ai->[$iterator + 1];
                my $j = $self->DetectASCII(2, $ai2, $ai3, $as1);
				splice(@$ai1,$j1,$j, @$ai3[0 .. $j-1 ]);
                $j1 += $j;
                $iterator++;
                $iterator++;
                $flag1 = 1;
                $l2 = E_ASCII;
            }
            if(!$flag1) {
            	#my $l1 = C3(@$ai, $self->{currentEncoding}, $iterator, @$as);
            	my $l1 = $self->SelectEncoding( $iterator );
                if( $l1 != E_ASCII) {
                	$l2 = $self->{currentEncoding};
                	$self->{currentEncoding} = $l1;
                }
            }
        	if(!$flag1 && $self->{currentEncoding} == E_ASCII){
                $ai1->[$j1++] = 254 if($l2 != E_ASCII);
                $ai2->[0] = $ai->[$iterator];
                $as1->[0] = $as->[$iterator];
                my $k = $self->DetectASCII(1, $ai2, $ai3, $as1);
                $as1->[0] = undef;
				splice(@$ai1,$j1,$k, @$ai3[0 .. $k-1 ]);
                $j1 += $k;
                $iterator++;
                $l2 = E_ASCII;
            }
        }
        my $i2;
        #warn "DetectEncoding < $iterator < $i > : i2: [$i2] ".typeToString($i2)."\n";
    	for(; $self->{currentEncoding} == E_C40 && $iterator < $i; $self->{currentEncoding} = $i2) {
            $ai4->[0] = $iterator;
            my $l = $self->Check6($i, $ai4, $ai, $ai3, 0, $l2 != E_C40, 1);
            $iterator = $ai4->[0];
			splice(@$ai1,$j1,$l, @$ai3[0 .. $l-1 ]);
            $j1 += $l;
        	$i2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        }

        my $j2;
    	for(; $self->{currentEncoding} == E_TEXT && $iterator < $i; $self->{currentEncoding} = $j2) {
            $ai4->[0] = $iterator;
            my $i1 = $self->Check6($i, $ai4, $ai, $ai3, 1, $l2 != E_TEXT, 1);
            $iterator = $ai4->[0];
			splice(@$ai1,$j1,$i1, @$ai3[0 .. $i1-1 ]);
            $j1 += $i1;
        	$j2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        }

    	if($self->{currentEncoding} == E_BASE256) {
            $ai4->[0] = $iterator;
            $ai5->[0] = $j1;
            $self->CheckBase256($i, $ai4, $ai, $ai5, $ai1, 1, $as);
            $iterator = $ai4->[0];
            $j1 = $ai5->[0];
        	my $k2 = $self->SelectEncoding($iterator);
        	$l2 = $self->{currentEncoding};
        	$self->{currentEncoding} = $k2;
        }
    }
    return $j1;
}


sub DetectASCII { #CE (int i; int ai[], int ai1[], String as[]) : int 
	my $self = shift;
	warn "[CE] DetectASCII(@_)\n" if $DEBUG{TRACE};
	my ($i,$ai,$ai1,$as) = @_;
	warn "ai:{".join(" ",grep{+defined}@$ai)."}; ai1:{".join(" ",grep{+defined}@$ai1)."}; as:{".join(" ",grep{+defined}@$as)."}\n" if $DEBUG{ENC};
    my $j = 0;
    my $flag = 0;
    for(my $k = 0; $k < $i; $k++) {
        my $flag1 = 0;
        if(	
        	$k < $i - 1 
        	and isIDigit($ai->[$k])
        	and isIDigit($ai->[$k+1])
        ) {
            my $l = ($ai->[$k] - 48) * 10 + ($ai->[$k + 1] - 48);
            $ai1->[$j++] = 130 + $l;
            $k++;
            $flag1 = 1;
        }
        if(!$flag1 and defined $as->[$k]) {
            if(
            	   $ai->[$k] == 234
            	|| $ai->[$k] == 237
            	|| $ai->[$k] == 236
            	|| $ai->[$k] == 232
            ) {
                $ai1->[$j++] = $ai->[$k];
                $flag1 = 1;
            }
            if($ai->[$k] == 233 || $ai->[$k] == 241) {
                $ai1->[$j++] = $ai->[$k];
                warn("Additional data by 233/241 for $k: $as->[$k]");
                for(my $i1 = 0; $i1 < length $as->[$k]; $i1++){
                    $ai1->[$j++] = ord substr($as->[$k],$i1,1);
                }
                $flag1 = 1;
            }
        }
        if(!$flag1){
            if($ai->[$k] < 128) {
                $ai1->[$j++] = $ai->[$k] + 1;
            } else {
                $ai1->[$j++] = 235;
                $ai1->[$j++] = ($ai->[$k] - 128) + 1;
            }
        }
    }
    warn R::Dump( \@_ );
    return $j;
}

sub SelectEncoding #C3 (int ai[], int i, int j, String as[]) : int # DefineEncoding??
                   #iterator, ai, encoding
{
	#(iterator[,ai[,encoding]])
	#(ai,i: encoding,j: iterator,as)
	my $self = shift;
	warn "[C3] SelectEncoding(@_)\n" if $DEBUG{TRACE};
	
	my $j = shift;
	
	my $ai = shift;
	$ai = $self->{ai} unless defined $ai;

	my $i = shift || $self->{currentEncoding};
	$i = $self->{currentEncoding} unless defined $i;
	
	my $as = $self->{as};
	my ($j) = @_;
    my $d  = 0.0;
    my $d2 = 1.0;
    my $d3 = 1.0;
    my $d4 = 1.25;
    my $k = $j;
    if($i != E_ASCII)
    {
        $d  = 1.0;
        $d2 = 2.0;
        $d3 = 2.0;
        $d4 = 2.25;
    }
    $d2 = 0.0 if $i == E_C40;
    $d3 = 0.0 if $i == E_TEXT;
    $d4 = 0.0 if $i == E_BASE256;
    for(; $j < @$ai; $j++)
    {
        my $c = $ai->[$j];
        return E_ASCII if defined $as->[$j];
        
        if    ( isIDigit($c) )        { $d += 0.5 }
        elsif ( $c > 127 )            { $d = int( $d + 0.5 ) + 2; }
        else                          { $d = int( $d + 0.5 ) + 1; }
        
        if    ( @{ $C1->[$c] } == 1 ) { $d2 += 0.66000000000000003; }
        elsif ( $c > 127 )            { $d2 += 2.6600000000000001; }
        else                          { $d2 += 1.3300000000000001; }
        my $c1 = $c;
        my $s = "" . chr($c);
        if( isIUpper($c) )            { $c1 = lc(chr($c)); }
        if( isILower($c) )            { $c1 = uc(chr($c)); }
        
        if    ( @{ $C1->[$c1] } == 1) { $d3 += 0.66000000000000003; }
        elsif ( $c1 > 127 )           { $d3 += 2.6600000000000001; }
        else                          { $d3 += 1.3300000000000001; }
        $d4++;
        
        if($j - $k >= 4) {
            return E_ASCII   if $d  + 1.0 <= $d2 && $d + 1.0 <= $d3 && $d + 1.0 <= $d4;
            return E_BASE256 if $d4 + 1.0 <= $d;
            return E_BASE256 if $d4 + 1.0 < $d3 && $d4 + 1.0 < $d2;
            return E_TEXT    if $d3 + 1.0 < $d && $d3 + 1.0 < $d2 && $d3 + 1.0 < $d4;
            return E_C40     if $d2 + 1.0 < $d && $d2 + 1.0 < $d3 && $d2 + 1.0 < $d4;
        }
    }

    $d  = int( $d + 0.5 );
    $d2 = int( $d2 + 0.5 );
    $d3 = int( $d3 + 0.5 );
    $d4 = int( $d4 + 0.5 );
    return E_ASCII   if $d <= $d2 && $d <= $d3 && $d <= $d4;
    return E_TEXT    if $d3 < $d && $d3 < $d2 && $d3 < $d4;
    return E_BASE256 if $d4 < $d && $d4 < $d3 && $d4 < $d2;
    return E_C40;
}

sub Check6 { # C6 #(int i, int ai[], int ai1[], int ai2[], boolean flag, boolean flag1, boolean flag2) : int
	#warn "[C6] Check6\n";
	my $self = shift;
	my ($i,$ai,$ai1,$ai2,$flag,$flag1,$flag2) = @_;
    my $j = my $k = 0;
    my $ai3 = [ 0, 0, 0 ];
    my $flag3 = 0;
    my $as = [  ];
    if($flag1) {
        $ai2->[$j++] = $flag ? 239 : 230;
    }
    for(my $j1 = $ai->[0]; $j1 < $i; $j1++) {
        my $l = $ai1->[$j1];
        if($flag) {
            my $s = chr($l);
            $s = uc($s) if($l >= 97 && $l <= 122);
            $s = lc($s) if($l >= 65 && $l <= 90);
            $l  = ord(substr($s,0,1));
        }
        my $ai4 = $C1->[$l];
        for my $l1 (0 .. $#$ai4) {
            $ai3->[$k++] = $ai4->[$l1];
            if($k == 3) {
                my $i2 = $ai3->[0] * 1600 + $ai3->[1] * 40 + $ai3->[2] + 1;
                $ai2->[$j++] = $i2 / 256;
                $ai2->[$j++] = $i2 % 256;
                $k = 0;
            }
        }

        if($flag2 && $k == 0) {
        	$self->{C49rest} = $k;
            $ai->[0] = $j1 + 1;
            $ai2->[$j++] = 254 if($ai->[0] == $i);
            return $j;
        }
    }

    $ai->[0] = $i;
    if($k > 0) {
        if($k == 1) {
            $ai2->[$j++] = 254;
            $ai2->[$j++] = $ai1->[$i - 1] + 1;
            return $j;
        }
        if($k == 2) {
            $ai3->[2] = 0;
            my $k1 = $ai3->[0] * 1600 + $ai3->[1] * 40 + $ai3->[2] + 1;
            $ai2->[$j++] = $k1 / 256;
            $ai2->[$j++] = $k1 % 256;
            $ai2->[$j++] = 254;
        	$self->{C49rest} = $k;
            return $j;
        }
    } else {
        $ai2->[$j++] = 254;
    }
    $self->{C49rest} = $k;
    return $j;
}

sub A253($$) # C8 (int i, int j) : int 
{
	my ($i,$j) = @_;
    my $l = $i + (149 * $j) % 253 + 1;
    return $l <= 254 ? $l : $l - 254;
}

sub state255($$) # (int V, int P) : int
{
	#The 255-state algorithm.
	#Let P the number of data CWs from the beginning of datas,
	#R a pseudo random number,
	#V the base 256 CW value and CW the required CW.
	#R = ((149 * P) MOD 255) + 1
	#CW = (V + R) MOD 256
    my ($V,$P) = @_;
    return ( $V + (149 * $P) % 255 + 1 ) % 256;
}

sub hexary {
	join(" ",map{ sprintf '%02x',$_} @{ shift() } )
}

sub decary {
	join(" ",map{ sprintf '%3d',$_} @{ shift() } )
}

sub CheckBase256 # C5 (int i, int ai[], int ai1[], int ai2[], int ai3[], boolean flag, String as[]) : int
{
	#warn "[C5] CheckBase256\n";
	my $self = shift;
	my ($i,$ai,$ai1,$ai2,$ai3,$flag) = @_;
    my $j = 0;
    my $ai4 = [];
    my $k = 
    my $l = $ai2->[0];
    my $flag1 = 0;
    my $j1 = 0;
    warn "AI1{".hexary($ai1)."}\n" if $DEBUG{B256};
    warn "AI4{".hexary($ai4)."}\n" if $DEBUG{B256};
    for($j1 = $ai->[0]; $j1 < $i; $j1++){
        $ai4->[$j] = $ai1->[$j1];
        $j++;
        my $i1 = $j1 + 1;
        last if($flag && $self->SelectEncoding($i1,$ai1,E_BASE256) != E_BASE256);
    }
    warn "AI1{".hexary($ai1)."}\n" if $DEBUG{B256};
    warn "AI4{".hexary($ai4)."}\n" if $DEBUG{B256};
	#warn "$j1 : $l\n";
    $ai->[0] = $j1;
    $ai3->[$l++] = 231;
    if($j < 250) {
    	#warn "ai3[$l] = state255($j, $l + 1);\n";
        $ai3->[$l] = state255($j, $l + 1);
        $l++;
    } else {
    	#warn "ai3[$l] = state255($j, $l + 1);\n";
        $ai3->[$l] = state255(249 + ($i - $i % 250) / 250, $l + 1);
        $l++;
        $ai3->[$l] = state255($i % 250, $l + 1);
        $l++;
    }
    for(my $k1 = 0; $k1 < $j; $k1++) {
        $ai3->[$l] = state255($ai4->[$k1], $l + 1);
        #warn "Base256: $ai4->[$k1] at $l => $ai3->[$l]\n";
        $l++;
    }
    $ai2->[0] = $l;
    return $l;
}

sub GenData { # CC (int ai[]) : int[][]
    my $self = shift;
    my ($ai) = @_;
    warn "[CC] GenData: ".join(",",@$ai)." [$self->{rows} x $self->{cols} : $self->{regions} : $self->{datacols}x$self->{datarows}]\n" if $DEBUG{TRACE};
	my $ai1 = [ map { [ (undef) x $self->{rows} ] } 1..$self->{cols} ]; # reverse cols/rows here, for correct access ->[][]
	
    my $i = my $j = 0;
    # Draw border
    if($self->{regions} == 2) {
		FillBorder($ai1, $i, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    	FillBorder($ai1, $i + $self->{datacols} + 2, $j, $self->{datacols} + 2, $self->{datarows} + 2);
    } else {
    	my $k = int(sqrt($self->{regions}));
        for(my $l = 0; $l < $k; $l++){
            for(my $i1 = 0; $i1 < $k; $i1++) {
            	FillBorder($ai1, $i + $l * ($self->{datacols} + 2), $j
            		+ $i1 * ($self->{datarows} + 2),
            		$self->{datacols} + 2, $self->{datarows} + 2);
			}
        }

    }
    # End draw border
	my $ai2 = [ (undef) x ( ($self->{mapcols} + 10) * $self->{maprows} ) ];
    warn "[" . join (" ", grep { +defined } @$ai2)."]\n" if $DEBUG{CALC};
	FillCharData($self->{mapcols},$self->{maprows},$ai2);
    warn "[" . join (" ", grep { +defined } @$ai2)."]\n" if $DEBUG{CALC};
	warn "--------------\n" if $DEBUG{CALC};
    warn "[" . join (" ", grep { +defined } @$ai)."]\n" if $DEBUG{CALC};
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
                $ai1->[$l1][$k1] = $j3;
            } else {
            	$ai1->[$l1][$k1] = $ai2->[$i2 * $self->{mapcols} + $k2];
            }
        	if($k2 > 0 && ($k2 + 1) % $self->{datacols} == 0) {
                $j2 += 2;
            }
        }

    	if($i2 > 0 && ($i2 + 1) % $self->{datarows} == 0) {
            $j1 += 2;
        }
    }
    return $ai1;
}

sub FillBorder { # CD (int ai[][], int i, int j, int k, int l) : void
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

sub FillCharData { # (int ncol; int nrow; int array;) : void
	my ($ncol,$nrow,$array) = @_;
	GD::Barcode::DataMatrix::CharDataFiller->new($ncol,$nrow,$array);
	return;
}

1;
__END__
package GD::Barcode::DataMatrix::Engine::CharDataFiller;

use strict;

sub new {
	my $self = bless {}, shift;
	@$self{qw( ncol nrow array )} = @_;
	$self->fill();
	return $self;
}

sub module {
	my ($self,$i,$j,$k,$l) = @_;
    if($i < 0) {
    	$i += $self->{nrow};
        $j += 4 - ($self->{nrow} + 4) % 8;
    }
    if($j < 0) {
        $j += $self->{ncol};
        $i += 4 - ($self->{ncol} + 4) % 8;
    }
    $self->{array}->[$i * $self->{ncol} + $j] = 10 * $k + $l;
    return;
}

sub utah {
	my ($self,$i,$j,$k) = @_;
    $self->module($i - 2, $j - 2, $k, 1);
    $self->module($i - 2, $j - 1, $k, 2);
    $self->module($i - 1, $j - 2, $k, 3);
    $self->module($i - 1, $j - 1, $k, 4);
    $self->module($i - 1, $j, $k, 5);
    $self->module($i, $j - 2, $k, 6);
    $self->module($i, $j - 1, $k, 7);
    $self->module($i, $j, $k, 8);
    return;
}

sub corner1 {
	my ($self,$i) = @_;
	my ($ncol,$nrow) = @$self{qw( ncol nrow )};
    $self->module($nrow - 1, 0, $i, 1);
    $self->module($nrow - 1, 1, $i, 2);
    $self->module($nrow - 1, 2, $i, 3);
    $self->module(0, $ncol - 2, $i, 4);
    $self->module(0, $ncol - 1, $i, 5);
    $self->module(1, $ncol - 1, $i, 6);
    $self->module(2, $ncol - 1, $i, 7);
    $self->module(3, $ncol - 1, $i, 8);
    return;
}

sub corner2($) { #(int i)
	my ($self,$i) = @_;
	my ($ncol,$nrow) = @$self{qw( ncol nrow )};
    $self->module($nrow - 3, 0, $i, 1);
    $self->module($nrow - 2, 0, $i, 2);
    $self->module($nrow - 1, 0, $i, 3);
    $self->module(0, $ncol - 4, $i, 4);
    $self->module(0, $ncol - 3, $i, 5);
    $self->module(0, $ncol - 2, $i, 6);
    $self->module(0, $ncol - 1, $i, 7);
    $self->module(1, $ncol - 1, $i, 8);
    return;
}

sub corner3($) { #(int i)
	my ($self,$i) = @_;
	my ($ncol,$nrow) = @$self{qw( ncol nrow )};
    $self->module($nrow - 3, 0, $i, 1);
    $self->module($nrow - 2, 0, $i, 2);
    $self->module($nrow - 1, 0, $i, 3);
    $self->module(0, $ncol - 2, $i, 4);
    $self->module(0, $ncol - 1, $i, 5);
    $self->module(1, $ncol - 1, $i, 6);
    $self->module(2, $ncol - 1, $i, 7);
    $self->module(3, $ncol - 1, $i, 8);
    return;
}

sub corner4($) { #(int i)
	my ($self,$i) = @_;
	my ($ncol,$nrow) = @$self{qw( ncol nrow )};
    $self->module($nrow - 1, 0, $i, 1);
    $self->module($nrow - 1, $ncol - 1, $i, 2);
    $self->module(0, $ncol - 3, $i, 3);
    $self->module(0, $ncol - 2, $i, 4);
    $self->module(0, $ncol - 1, $i, 5);
    $self->module(1, $ncol - 3, $i, 6);
    $self->module(1, $ncol - 2, $i, 7);
    $self->module(1, $ncol - 1, $i, 8);
    return;
}

sub fill { # (int ncol; int nrow; int array;) : void
	my $self = shift;
	my ($ncol,$nrow,$array) = @$self{qw( ncol nrow array )};
    my $i = 1;
    my $j = 4;
    my $k = 0;
    for(my $l = 0; $l < $nrow; $l++) {
        for(my $i1 = 0; $i1 < $ncol; $i1++) {
            $array->[$l * $ncol + $i1] = 0;
        }
    }
    do {
        $self->corner1($i++) if $j == $nrow && $k == 0;
        $self->corner2($i++) if $j == $nrow - 2 && $k == 0 && $ncol % 4 != 0;
        $self->corner3($i++) if $j == $nrow - 2 && $k == 0 && $ncol % 8 == 4;
        $self->corner4($i++) if $j == $nrow + 4 && $k == 2 && $ncol % 8 == 0;
        do {
            $self->utah($j, $k, $i++) if $j < $nrow && $k >= 0 && $array->[$j * $ncol + $k] == 0;
            $j -= 2;
            $k += 2;
        } while($j >= 0 && $k < $ncol);
        $j++;
        $k += 3;
        do {
            $self->utah($j, $k, $i++) if $j >= 0 && $k < $ncol && $array->[$j * $ncol + $k] == 0;
            $j += 2;
            $k -= 2;
        } while($j < $nrow && $k >= 0);
        $j += 3;
        $k++;
    } while($j < $nrow || $k < $ncol);
    $array->[$nrow * $ncol - 1] = $array->[($nrow - 1) * $ncol - 2] = 1
    	if($array->[$nrow * $ncol - 1] == 0);
    return;
}

1;