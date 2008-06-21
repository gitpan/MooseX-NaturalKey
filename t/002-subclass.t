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

    package MooseX::NaturalKey::Test2;
    use MooseX::NaturalKey;

    extends "MooseX::NaturalKey::Test";

    package MooseX::NaturalKey::Test3;
    use MooseX::NaturalKey;
    extends "MooseX::NaturalKey::Test2";

    primary key => 'details';
}

my $moose = MooseX::NaturalKey::Test2->new
	( name => "Bob", details => "Cheese" );

isa_ok($moose, 'MooseX::NaturalKey::Test2',
       'NaturalKey->new returns a real instance');

{
	my $elk = MooseX::NaturalKey::Test2->new
		( name => "Le Bob", details => "Fromage" );

	isnt($moose, $elk, "different instances");

	my $le_bob = MooseX::NaturalKey::Test2->new
		( name => "Le Bob" );

	is($le_bob, $elk, "same instance");

	my $bob_ish = MooseX::NaturalKey::Test->new
		( name => "Le Bob" );

	is($bob_ish, $elk, "selectors inherit");

	my $test_3 = MooseX::NaturalKey::Test3->new
		( name => "Le Bob",
		  details => "Le Bob" );

	isnt($test_3, $le_bob, "primary key makes a new object cache");
}

my $bob = MooseX::NaturalKey::Test2->new
	( name => "Bob" );

is($bob, $moose, "Same instance");

my $le_bob_ii  = MooseX::NaturalKey::Test2->new
	( name => "Le Bob" );

is($le_bob_ii->details, undef, "object fell out of scope OK");
