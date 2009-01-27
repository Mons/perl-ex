use inc::Module::Install;

name     'lvalue';
all_from 'lib/lvalue.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

