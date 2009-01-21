use warnings;
use strict;

package Geo::GML::Util;
use base 'Exporter';

our @gml200  = qw/NS_GML_200  NS_XLINK_1999/;
our @gml211  = qw/NS_GML_211  NS_XLINK_1999/;
our @gml212  = qw/NS_GML_212  NS_XLINK_1999/;
our @gml2120 = qw/NS_GML_2120 NS_XLINK_1999/;
our @gml2121 = qw/NS_GML_2121 NS_XLINK_1999/;
our @gml300  = qw/NS_GML_300  NS_XLINK_1999 NS_SMIL_20/;
our @gml301  = qw/NS_GML_301  NS_XLINK_1999 NS_SMIL_20/;
our @gml310  = qw/NS_GML_310  NS_XLINK_1999 NS_SMIL_20/;
our @gml311  = qw/NS_GML_311  NS_XLINK_1999 NS_GML_311_SF NS_SMIL_20/;

our @gml321  = qw/NS_GML_32 NS_GML_321
  NS_GMD_2005 NS_SMIL_20 NS_XLINK_1999/;

our @proto   = qw/NS_GML NS_GML_32 NS_GML_SF/;

our @EXPORT  =
 ( @proto
 , @gml200, @gml211, @gml212, @gml2120, @gml2121
 , @gml300, @gml301, @gml310, @gml311, @gml321
 );

our %EXPORT_TAGS =
 ( gml200    => \@gml200
 , gml211    => \@gml211
 , gml212    => \@gml212
 , gml2120   => \@gml2120
 , gml2121   => \@gml2121
 , gml300    => \@gml300
 , gml301    => \@gml301
 , gml310    => \@gml310
 , gml311    => \@gml311
 , gml321    => \@gml321
 , protocols => \@proto
 );

=chapter NAME
Geo::GML::Util - GML useful constants

=chapter SYNOPSIS
  use Geo::GML;
  use Geo::GML::Util ':gml311';

=chapter DESCRIPTION

XML uses long URLs to represent name-spaces, which must be used without
typos.  Therefore, it is better to use constants instead: the main
purpose for this module.

=chapter FUNCTIONS

=section Constants

=subsection Export Tag :protocols
This tag will give you access to the the name-space constants for
all recognisable GML versions, like NS_GML_32.

=cut

use constant NS_GML        => 'http://www.opengis.net/gml';
use constant NS_GML_32     => 'http://www.opengis.net/gml/3.2';

# used in various schemas
use constant NS_GMD_2005   => 'http://www.isotc211.org/2005/gmd';
use constant NS_SMIL_20    => 'http://www.w3.org/2001/SMIL20/';
use constant NS_XLINK_1999 => 'http://www.w3.org/1999/xlink';

=subsection Export Tags

The following tags define all what you need per version.

  :gml200    2.0.0
  :gml211    2.1.1
  :gml212    2.1.2
  :gml2120   2.1.2.0
  :gml2121   2.1.2.1
  :gml300    3.0.0
  :gml301    3.0.1
  :gml310    3.1.0
  :gml311    3.1.1
  :gml321    3.2.1

=cut

use constant NS_GML_200    => NS_GML;
use constant NS_GML_211    => NS_GML;
use constant NS_GML_212    => NS_GML;
use constant NS_GML_2120   => NS_GML;
use constant NS_GML_2121   => NS_GML;
use constant NS_GML_300    => NS_GML;
use constant NS_GML_301    => NS_GML;
use constant NS_GML_310    => NS_GML;
use constant NS_GML_311    => NS_GML;
use constant NS_GML_321    => NS_GML_32;

use constant NS_GML_SF     => 'http://www.opengis.net/gmlsf';
use constant NS_GML_311_SF => NS_GML_SF;

1;
