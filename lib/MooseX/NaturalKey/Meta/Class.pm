#!/usr/bin/env perl
package MooseX::NaturalKey::Meta::Class;

use Moose;
use Scalar::Util qw(weaken);
use Carp qw(confess);

extends 'Moose::Meta::Class';

has 'primary_key' =>
	isa => 'ArrayRef[Str]',
	is => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->meta_attribute_fetch("primary_key");
	};

sub set_default_cache {
	my $self = shift;
	no strict 'refs';
	my $pkg = $self->name;
	no warnings 'once';
	$self->cache(\%{"${pkg}::instances"});
}

has 'cache' =>
	isa => "HashRef",
	is => "rw",
	required => 1,
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->meta_attribute_fetch("cache");
	};

# this searches up the metaclass object tree for the next class
# with this property defined.
sub meta_attribute_fetch {
	my $self = shift;
	my $att = shift;
	for my $class ($self->linearized_isa) {
		next if $class eq $self->name;
		my $mc = $class->meta;
		$DB::single = 1;
		if (my $ma = $mc->meta->get_attribute($att)) {
			my $val = $ma->get_value($mc);
			return $val if defined $val;
		}
	}
}

sub make_cache_key {
	my $class = shift;
	my $candidate = shift;
	my $primary_key = shift;
	join "\0", map {
		confess __PACKAGE__.": can't handle reference ($_) as"
			." primary key" if ref $_;
		if ( defined ($_) ) {
			s{\\}{\\\\}g;
			s{\0}{\\0}g;
		}
		defined($_) ? $_ : "\\N"
	} @$primary_key
}

override construct_instance => sub {
	my ($class) = @_;

	my $instance = super;

	#$DB::single = 1;
	my $candidate = $class->primary_key
		or confess "class '".$class->name."' has not defined a "
			."primary key yet; can't construct instance";

	my $primary_key = [map {
		$class->instance_metaclass->get_slot_value($instance, $_);
	} @$candidate];

	my $cache = $class->cache();
	my $cache_key = $class->make_cache_key($candidate, $primary_key);

	if ( $cache->{$cache_key} ) {
		return $cache->{$cache_key};
	}
	else {
		$cache->{$cache_key} = $instance;
		weaken($cache->{$cache_key});
		return $instance;
	}
};

1;

__END__

=pod

=head1 NAME

MooseX::NaturalKey::Meta::Class

=head1 SYNOPSIS

    # in your class which mimics Moose.pm;
    sub import {
        my $caller = caller;
        Moose::init_meta
	    ($caller,
	     'Moose::Object',
	     'MooseX::NaturalKey::Meta::Class');

        Moose->import({ into => $caller });
    }

    # if you wanted special behaviour you could define:
    package My::NaturalKey::Meta::Class;
    extends 'MooseX::NaturalKey::Meta::Class

    # override where the instance cache comes from
    override cache => sub {
        my $self = shift;
        return \%cache;
    };

    # alternative method
    my %cache;
    __PACKAGE__->meta->cache(\%cache);

    # override how the primary keys are transformed into a
    # cache hash slot
    override make_cache_key => sub {
        my $self = shift;
        my $names_arrayref = shift;
        my $values_arrayref = shift;

        # example
        join "\0", @$values_arrayref;
    };


=head1 DESCRIPTION

This metaclass implements 'Natural Key' Moose classes.  So, when you
create a new MooseX::NaturalKey, it creates one of these objects.
During object construction, creating the actual instance is deferred
to the created object.

After the object is constructed as normal, it checks using the primary
keys list it knows about, what the values of those slots are in the
constructed object.

=head1 SEE ALSO

L<MooseX::NaturalKey>, L<Moose::Meta::Class>.

=head1 AUTHOR AND LICENSE

Copyright 2008, Sam Vilain, E<lt>samv@cpan.orgE<gt>.  All Rights
Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
