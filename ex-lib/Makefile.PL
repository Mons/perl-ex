use inc::Module::Install;

name     'ex-lib';
all_from 'lib/ex/lib.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';

# From 0.04 strictly rely on Cwd
#requires Cwd => '3.29';
requires Cwd => '3.26';
# FreeBDS: devel/p5-PathTools

auto_install;

WriteAll;

