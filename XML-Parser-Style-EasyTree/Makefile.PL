use inc::Module::Install;

name     'XML-Parser-Style-EasyTree';
all_from 'lib/XML/Parser/Style/EasyTree.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'ex::lib';

requires 'Scalar::Util';

auto_install;

WriteAll;

