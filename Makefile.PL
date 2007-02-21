use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::Plugin::Authentication::Store::DBIx::Class',
    AUTHOR              => 'Jay Kuri <jayk@cpan.org>',
    VERSION_FROM        => 'lib/Catalyst/Plugin/Authentication/Store/DBIx/Class.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/Plugin/Authentication/Store/DBIx/Class.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-Plugin-Authentication-Store-DBIx-Class-*' },
);
