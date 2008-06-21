package MooseX::NaturalKey;
use Moose;
use MooseX::NaturalKey::Meta::Class;
use Sub::Exporter;

our $VERSION = 0.02;

sub primary {
	shift if $_[0] eq "key";
	my $caller = caller;
	my @keys = @_;

	my $meta = $caller->meta;
	$meta->primary_key(\@keys);
	$meta->set_default_cache;
}

our $exporter;
{
	$exporter = Sub::Exporter::build_exporter
		( { exports => [ qw(primary) ],
		    groups  => { default => [':all'] }
		  } );
}

sub import {
	my $caller = caller;

	Moose::init_meta
		($caller,
		 'Moose::Object',
		 'MooseX::NaturalKey::Meta::Class');

	Moose->import({into => $caller});
	strict->import;
	warnings->import;
	goto $exporter;  # goto++
}

sub unimport {
	my $caller = caller;

	Moose->unimport({into => $caller});
	no strict 'refs';
	if ( defined &{ $caller . '::primary' } and
	     *{ ${ $caller . '::' }{primary} }{CODE} == \&primary
	   ) {
		delete ${ $caller . '::' }{primary};
	}
}

no Moose;

1;

__END__

=pod

=head1 NAME

MooseX::NaturalKey - make your constructor a candidate key match

=head1 VERSION

Version 0.02, released 21 Jun 08

=head1 SYNOPSIS

    package Person;
    use MooseX::NaturalKey;

    has 'name' =>
        isa => 'Str',
        is => 'ro';

    use MooseX::TimestampTZ;
    has 'birthdate' =>
        isa => 'MooseX::TimestampTZ',
        is => 'ro';

    primary key => ('name', 'birthdate');

    package main;

    my $person = Person->new
        ( name => "Sam Vilain",
          birthdate => "1979-01-17 14:00Z" );

    my $other_person = Person->new
        ( name => "Sam Vilain",
          birthdate => "1979-01-17 14:00Z" );

    # but it's the same object!
    use Scalar::Util qw(refaddr);
    die unless refaddr($person) == refaddr($other_person);

=head1 DESCRIPTION

Normally, objects you create have a I<surrogate identifier>, which is
their I<instance>.  Using classes such as L<MooseX::Singleton>, you
can break this pattern and use the type of the class as its
identifier.

However, sometimes you want something half-way; it's not quite right
to use a surrogate and it's not quite right to use a singleton,
either.  In a sense, you want to turn your constructor into a
B<candidate key> search for any objects which have the same primary
identifier - be it a database name for a set of database handles.

=head1 DESIGN DECISIONS

Many arbitrary behavioural decisions are made, and below I outline the
important ones.

=head2 wrt EXISTING OBJECTS

If an existing object is found, new properties that you passed in are
B<discarded> and the old object is returned.  If you want to change
the existing properties when the object already exists, you'll have to
explicitly code that, like so:

  my $obj = My::Object->new(name => "Bob");
  $obj->age(32);

Instead of:

  my $obj = My::Object->new(name => "Bob", age => 32);

B<Rationale>: avoid unnecessary arbitrary decisions about how to
combine the information from the prototype object and the existing
object.

=head2 wrt INHERITANCE

When you sub-class a class with a natural key, I<its primary key also
inherits>.  It also inherits the cache of objects.  So, an "empty"
subclass will be considered in the same bunch as the original, making
the "empty subclass" test work.

However, you must use the same metaclasses in your sub-class,
otherwise you will not experience the results you expected.

In this example, the second constructor refers to the first object;

  package Brother;
  use MooseX::NaturalKey;
  extends "Person";
  has 'siblings' => isa => "ArrayRef[Person]";

  package main;
  use MooseX::TimestampTZ qw(now);
  my $sam = Brother->new
      ( name => "Sam Vilain",
        birthdate => "1979-01-17 14:00Z" );

  my $also_sam = Person->new
      ( name => "Sam Vilain",
        birthdate => "1979-01-17 14:00Z" );

If you declare a new primary key, this is not the case:

  package Corporation;
  use MooseX::NaturalKey;
  extends "Person";
  has 'country' => isa => Str;
  primary key => ('name', 'country');

Setting the primary key makes a new namespace.

=head2 wrt PRIMARY KEY VALUES

Currently, only non-references are allowed.  Discussion/patches
welcome.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.  In fact, given the lack of test cases it's quite likely
that something doesn't work.

If you find an error, please submit the failure as an addition to the
test suite, as a patch.  Version control is at:

 git://utsl.gen.nz/MooseX-NaturalKey

See the file F<SubmittingPatches> in the distribution for a basic
command sequence you can use for this.  Feel free to also harass me
via L<http://rt.cpan.org/> or mailing me something other than a patch,
but you win points for submitting in `git-format-patch` format.

=head1 AUTHORS, COPYRIGHT AND LICENSE

MooseX::NaturalKey version 0.01 is Copyright 2008, Sam Vilain
E<lt>samv@cpan.org<gt>.

There may be some traces of code remaining from L<MooseX::Singleton>,
Copyright 2007, 2008 by Shawn M Moore E<lt>sartak@gmail.comE<gt>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
