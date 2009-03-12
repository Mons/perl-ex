use inc::Module::Install;

name     'ex-lib';
all_from 'lib/ex/lib.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';

#requires Cwd => '3.25';
requires Cwd => '3.12';

# FreeBDS: devel/p5-PathTools

auto_install;

WriteAll;

