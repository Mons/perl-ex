use inc::Module::Install;

name     'Captcha-Easy';
all_from 'lib/Captcha/Easy.pm';
author   'Mons Anderson <mons@cpan.org>';
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

