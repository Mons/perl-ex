use inc::Module::Install;

name     'constant-def';
author   'Mons Anderson <mons@cpan.org>';
all_from 'lib/constant/def.pm';
version   my $v = '0.02';

build_requires 'Test::More';
build_requires 'lib::abs' => '0.90';

requires 'constant' => 1.05;

provides 'constant::def' => {
	version => $v,
	file    => 'lib/constant/def.pm',
};

provides 'constant::abs' => {
	version => $v,
	file    => 'lib/constant/abs.pm',
};

auto_install;

WriteAll;

