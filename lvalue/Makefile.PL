use inc::Module::Install;

name     'lvalue';
all_from 'lib/lvalue.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'ex::lib', 0.03;

requires 'Sub::Name';

auto_install;

WriteAll;

