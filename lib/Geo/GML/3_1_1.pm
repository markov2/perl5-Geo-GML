use warnings;
use strict;

package Geo::GML::3_1_1;
use base 'Geo::GML';

use Geo::GML::Util qw/:gml311/;
use Log::Report 'geo-gml', syntax => 'SHORT';

my $xsd = __FILE__;
$xsd    =~ s!/[0-9_]+\.pm$!/xsd!;
my @xsd = ( glob("$xsd/gml3.1.1/{base,smil,xlink}/*.xsd")
          , glob("$xsd/gml3.1.1/profile/*/*/*.xsd")
          , glob("$xsd/xlink1.0.0/*.xsd")
          );

=chapter NAME
Geo::GML::3_1_1 - GML Specification 3.1.1

=chapter SYNOPSIS
=chapter DESCRIPTION
=chapter METHODS

=c_method new OPTIONS
=default version '3.1.1'
=default prefixes gml,gmlsf,smil,xlink
=cut

sub init($)
{   my ($self, $args) = @_;
    $args->{version} ||= '3.1.1';
    my $pref = $args->{prefixes} ||= {};
    $pref->{gml}   ||= NS_GML_311;
    $pref->{gmlsf} ||= NS_GML_311_SF;
    $pref->{smil}  ||= NS_SMIL_20;
    $pref->{xlink} ||= NS_XLINK_1999;

    $self->SUPER::init($args);
    $self->schemas->importDefinitions(\@xsd);
    $self;
}

1;
