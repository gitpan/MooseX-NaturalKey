use strict;
use warnings;
use inc::Module::Install;

name 'MooseX-NaturalKey';
all_from 'lib/MooseX/NaturalKey.pm';

requires 'Moose' => '0.50';
requires 'Sub::Exporter';

build_requires 'Test::More';
build_requires 'Test::Exception';

license 'Perl';

WriteAll();
