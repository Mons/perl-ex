use inc::Module::Install;

name     'Captcha-Easy';
all_from 'lib/Captcha/Easy.pm';
author   'Mons Anderson <mons@cpan.org>';
version   my $v = '0.03';
license  'perl';

build_requires 'lib::abs', '0.90';
build_requires 'Test::More';

requires 'Imager';
requires 'Digest::SHA1';
requires 'File::Find';

provides 'Captcha::Easy' => {
	version => $v,
	file    => 'lib/Captcha/Easy.pm',
};

auto_install;

WriteAll;

