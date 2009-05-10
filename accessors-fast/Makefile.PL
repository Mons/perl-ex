use inc::Module::Install;

name     'accessors-fast';
all_from 'lib/accessors/fast.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'ex::lib', '0.05';

requires 'constant::def', '0.01';
requires 'Class::Accessor::Fast';
requires 'Class::C3';
recommends 'Class::Accessor::Fast::XS';

auto_install;

WriteAll;

