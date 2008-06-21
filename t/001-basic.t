#!/usr/bin/perl

use strict;
use warnings;
use Test::More "no_plan";

BEGIN {
    package MooseX::NaturalKey::Test;
    use MooseX::NaturalKey;

    has name => (
        is      => 'ro',
        isa     => 'Str',
	required => 1,
    );

    has details => (
    	is => "rw",
	isa => "Str",
    );

    primary key => 'name';

}


my $moose = MooseX::NaturalKey::Test->new
	( name => "Bob", details => "Cheese" );

isa_ok($moose, 'MooseX::NaturalKey::Test',
       'NaturalKey->new returns a real instance');

{
	my $elk = MooseX::NaturalKey::Test->new
		( name => "Le Bob", details => "Fromage" );

	isnt($moose, $elk, "different instances");

	my $le_bob = MooseX::NaturalKey::Test->new
		( name => "Le Bob" );

	is($le_bob, $elk, "same instance");
}

my $bob = MooseX::NaturalKey::Test->new
	( name => "Bob" );

is($bob, $moose, "Same instance");

my $le_bob_ii  = MooseX::NaturalKey::Test->new
	( name => "Le Bob" );

is($le_bob_ii->details, undef, "object fell out of scope OK");
