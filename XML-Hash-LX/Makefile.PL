use inc::Module::Install 0.79;

name     'XML-Hash-LX';
all_from 'lib/XML/Hash/LX.pm';
version   my $v = '0.06';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';

requires 'XML::LibXML';# , '1.62'; # required DOM-compliant nodeNames

provides 'XML::Hash::LX' => {
	version => $v,
	file    => 'lib/XML/Hash/LX.pm',
};

auto_install;

WriteAll;
