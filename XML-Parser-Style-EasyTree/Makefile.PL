use inc::Module::Install;

name     'XML-Parser-Style-EasyTree';
all_from 'lib/XML/Parser/Style/EasyTree.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'ex::lib', '0.03';
build_requires 'XML::Parser';

requires 'Scalar::Util';

auto_install;

WriteAll;

