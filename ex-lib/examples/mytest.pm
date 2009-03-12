package mytest;

use Cwd 'cwd';
sub import {
	warn __PACKAGE__." use OK from ".cwd()."\n";
}

1;
