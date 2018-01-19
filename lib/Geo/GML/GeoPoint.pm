# This code is part of distribution Geo::GML.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

# extends the implementation of Geo::GML, autoloaded
package Geo::GML;

use warnings;
use strict;

use Log::Report 'geo-gml', syntax => 'SHORT';
use Geo::Point  ();

=chapter NAME
Geo::GML::GeoPoint - convert Geo::Point objects into GML

=chapter SYNOPSIS
 my $geopoint = Geo::Surface->new(...);
 my $gml  = Geo::GML->new('WRITER', version => '3.2.1');
 my $data;
 $data->{..somewhere..} = $gml->GPtoGML($geopoint);

=chapter DESCRIPTION
Convert Geo::Point objects into GML data structures.  The implementation
is partial: please help with providing me with examples.

=chapter METHODS
=cut

#---------------------------------

=section Helpers

=method GPtoGML $object, %options

=option  srs SRS-name
=default srs <from OBJECT>
Overrule the projection name as found in the M<Geo::Point> object, which
is just a simple label.  Be sure that your $object is in the correct
projection, for instance via

   $gml->GPtoGML($gp->in('wgs84'), srs => 'EPGS:4326');

=cut

sub GPtoGML($@)
{   my ($self, $object, %args) = @_;

    UNIVERSAL::isa($object, 'Geo::Shape')
        or error __x"GPtoGML requires Geo::Shape objects, not `{got}'"
             , got => (ref $object || $object);

    my $srs = $args{srs} || $object->proj || 'EPGS:4326';

    my $data;
    if($self->version lt 3)
    {   local $args{_srsName} = $srs;
        $data
        = $object->isa('Geo::Space')   ? $self->_gml2_space($object, \%args)
        : $object->isa('Geo::Surface') ? $self->_gml2_surface($object, \%args)
        : $object->isa('Geo::Line')    ? $self->_gml2_line($object, \%args)
        : $object->isa('Geo::Point')   ? $self->_gml2_point($object, \%args)
        : $object->isa('Geo::Shape')   ? $self->_gml2_shape($object, \%args)
        : panic("GPtoGML does not understand {type} yet", type => ref $object);

    }
    else
    {   $data
        = $object->isa('Geo::Space')   ? $self->_gml3_space($object, \%args)
        : $object->isa('Geo::Surface') ? $self->_gml3_surface($object, \%args)
        : $object->isa('Geo::Line')    ? $self->_gml3_line($object, \%args)
        : $object->isa('Geo::Point')   ? $self->_gml3_point($object, \%args)
        : $object->isa('Geo::Shape')   ? $self->_gml3_shape($object, \%args)
        : panic("GPtoGML does not understand {type} yet", type => ref $object);

        my ($k, $v) = %$data;   # always only one element
        $v->{srsName} = $srs;
    }

#warn Dumper $data;
    $data;
}

#
## GML2
#

sub _gml2_space($$)
{   my ($self, $space, $args) = @_;

    # wrong: Space can contain other objects as well.
    my @members;
    foreach my $c ($space->components)
    {   $c = Geo::Surface->new($c) if $c->isa('Geo::Line');
        push @members, { gml_polygonMember => $self->_gml2_surface($c, $args) };
    }

   +{ gml_MultiPolygon =>
      { seq_gml_polygonMember => \@members
       , srsName => $args->{_srsName}
      }
    };
}

sub _gml2_surface($$)
{   my ($self, $surface, $args) = @_;

    my $outer = $self->_gml2_line($surface->geoOuter, $args);
    my @inner = map $self->_gml2_line($_, $args), $surface->geoInner;

    my %poly  = ( gml_outerBoundaryIs => $outer
                , gml_innerBoundaryIs => \@inner);
   +{ gml_Polygon => \%poly
    };
}

sub _gml2_line($$)
{   my ($self, $line, $args) = @_;
    defined $line or return;

    my ($cs, $ts) = (',', ' ');
    my $coords = join $ts, map $_->[0].$cs.$_->[1], $line->points;

   +{ gml_LinearRing =>
      { gml_coordinates =>
         { _ => $coords
         , ts => $ts
         , cs => $cs
         }
      , srsName => $args->{_srsName}
      }
    };
}

sub _gml2_point($$)
{   my ($self, $point, $args) = @_;

   +{ gml_Point =>
      { gml_coord => { gml_X => $point->x, gml_Y => $point->y }
      , srsName => $args->{_srsName}
      }
    };
}

sub _gml2_shape($$)
{   my ($self, $shape, $args) = @_;
    panic "object type ".(ref $shape). "not implemented yet";
}

#
## GML3
#

sub _gml3_space($$)
{   my ($self, $space, $args) = @_;
    my @members;

    foreach my $c ($space->components)
    {  $c = Geo::Surface->new($c) if $c->isa('Geo::Line');
       push @members, $self->_gml3_surface($c, $args);
#         , $c->isa('Geo::Line')
#         ? $self->_gml3_line($c, $args)
#         : $self->_gml3_surface($c, $args);
    }

    my $surftype =
       $self->version lt '3.2' ? 'gml__Surface' : 'seq_gml_AbstractSurface';

   +{ gml_MultiSurface =>
      { gml_surfaceMembers =>
        { $surftype => \@members }
      }
    };
}

sub _gml3_surface($$)
{   my ($self, $surface, $args) = @_;
    my @members;

    my $outer = $self->_gml3_line($surface->geoOuter, $args);
    my @inner = map $self->_gml3_line($_, $args), $surface->geoInner;
    my %poly  = (gml_exterior => $outer, gml_interior => \@inner);
    +{ gml_Polygon => \%poly };
}

sub _gml3_line($$)
{   my ($self, $line, $args) = @_;
    $line or return;

    my @points = $line->points;
    my @coords = $line->proj4->isLatlong
       ? (map +($_->[1], $_->[0]), @points)
       : (map +($_->[0], $_->[1]), @points);

   +{ gml_LinearRing =>
      { gml_posList => { _ => \@coords, count => scalar(@points) } }
    };
}

sub _gml3_point($$)
{   my ($self, $point, $args) = @_;
    $point or return;

   +{ gml_Point =>
      { gml_pos => { _ => [$point->coordsUsualOrder] }
      }
    };
}

sub _gml3_shape($$)
{   my ($self, $shape, $args) = @_;
    panic "object type ".(ref $shape). "not implemented yet";
}

1;
