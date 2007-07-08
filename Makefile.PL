use inc::Module::Install 0.65;

name 'Catalyst-Plugin-Authentication-Store-DBIx-Class';
all_from 'lib/Catalyst/Plugin/Authentication/Store/DBIx/Class.pm';

requires 'Catalyst::Runtime';
requires 'Catalyst::Plugin::Authentication';
requires 'Test::More';

auto_install;
WriteAll;

