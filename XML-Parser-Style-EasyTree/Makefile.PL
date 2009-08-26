use inc::Module::Install;

name     'XML-Parser-Style-EasyTree';
all_from 'lib/XML/Parser/Style/ETree.pm';
abstract_from 'lib/XML/Parser/Style/EasyTree.pm';
author   'Mons Anderson <mons@cpan.org>';

build_requires 'Test::More';
build_requires 'lib::abs', '0.90';
build_requires 'XML::Parser';

requires 'Scalar::Util';

auto_install;

WriteAll;
