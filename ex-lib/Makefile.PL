use inc::Module::Install;

name     'ex-lib';
all_from 'lib/ex/lib.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

