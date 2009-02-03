use inc::Module::Install;

name     'accessors-fast';
all_from 'lib/accessors/fast.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

