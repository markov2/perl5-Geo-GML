use warnings;
use strict;

package Geo::GML::2_0_0;
use base 'Geo::GML';

use Geo::GML::Util qw/:gml200/;
use Log::Report 'geo-gml', syntax => 'SHORT';

my $xsd = __FILE__;
$xsd    =~ s!/[0-9_]+\.pm$!/xsd!;
my @xsd = ( glob("$xsd/gml2.0.0/*.xsd")
          , glob("$xsd/xlink1.0.0/*.xsd")
          );

=chapter NAME
Geo::GML::2_0_0 - GML Specification 2.0.0

=chapter SYNOPSIS
=chapter DESCRIPTION
=chapter METHODS

=c_method new OPTIONS
=default version '2.0.0'
=default prefixes gml,xlink
=cut

sub init($)
{   my ($self, $args) = @_;
    $args->{version} ||= '2.0.0';
    my $pref = $args->{prefixes} ||= {};
    $pref->{gml}   ||= NS_GML_200;
    $pref->{xlink} ||= NS_XLINK_1999;

    $self->SUPER::init($args);
    $self->schemas->importDefinitions(\@xsd);
    $self;
}

1;
