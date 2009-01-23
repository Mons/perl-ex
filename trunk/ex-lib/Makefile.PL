use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ex::lib',
    AUTHOR              => 'Mons Anderson <mons@cpan.org>',
    VERSION_FROM        => 'lib/ex/lib.pm',
    ABSTRACT_FROM       => 'lib/ex/lib.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ex-lib-*' },
);
