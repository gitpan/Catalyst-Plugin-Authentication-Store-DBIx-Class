#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Authentication::Store::DBIx::Class' );
}

diag( "Testing Catalyst::Plugin::Authentication::Store::DBIx::Class $Catalyst::Plugin::Authentication::Store::DBIx::Class::VERSION, Perl $], $^X" );
