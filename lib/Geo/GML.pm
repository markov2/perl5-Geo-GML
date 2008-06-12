use warnings;
use strict;

package Geo::GML;

use Geo::GML::Util;

use Log::Report 'geo-gml', syntax => 'SHORT';
use XML::Compile::Cache ();
use XML::Compile::Util  qw/unpack_type pack_type/;

# map namespace always to the newest implementation of the protocol
my %ns2version =
  ( &NS_GML    => '3.1.1'
  , &NS_GML_32 => '3.2.1'
  );

# list all available versions
my %info =
  ( '2.0.0'   => { prefixes => {gml => NS_GML_200}
                 , schemas  => [ 'gml2.0.0/*.xsd' ] }
  , '2.1.1'   => { prefixes => {gml => NS_GML_211}
                 , schemas  => [ 'gml2.1.1/*.xsd' ] }
  , '2.1.2'   => { prefixes => {gml => NS_GML_212}
                 , schemas  => [ 'gml2.1.2/*.xsd' ] }
  , '2.1.2.0' => { prefixes => {gml => NS_GML_2120}
                 , schemas  => [ 'gml2.1.2.0/*.xsd' ] }
  , '2.1.2.1' => { prefixes => {gml => NS_GML_2121}
                 , schemas  => [ 'gml2.1.2.1/*.xsd' ] }
  , '3.0.0'   => { prefixes => {gml => NS_GML_300, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.0.0/*/*.xsd' ] }
  , '3.0.1'   => { prefixes => {gml => NS_GML_301, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.0.1/*/*.xsd' ] }
  , '3.1.0'   => { prefixes => {gml => NS_GML_310, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.1.0/*/*.xsd' ] }
  , '3.1.1'   => { prefixes => {gml => NS_GML_311, smil => NS_SMIL_20
                               ,gmlsf => NS_GML_311_SF}
                 , schemas  => [ 'gml3.1.1/{base,smil,xlink}/*.xsd'
                               , 'gml3.1.1/profile/*/*/*.xsd' ] }
  , '3.2.1'   => { prefixes => {gml => NS_GML_321, smil => NS_SMIL_20 }
                 , schemas  => [ 'gml3.2.1/*.xsd' ] }
  );

# This list must be extended, but I do not know what people need.
my @declare_always =
    qw/gml:TopoSurface/;

=chapter NAME
Geo::GML - Geography Markup Language processing

=chapter SYNOPSIS
 use Geo::GML   qw/gml321/;

 my $gml = Geo::GML->new('READER', version => '3.2.1');

 # see XML::Compile::Cache on how to use readers and writers
 my $data = $gml->reader("gml:GridCoverage")->($xmlmsg);
 my $xml  = $gml->writer($sometype)->($doc, $perldata);

 # or without help of the cache, XML::Compile::Schema
 my $r    = $gml->schemas->compile(READER => $sometype);
 my $data = $r->($xml);

 # overview (large) on all defined elements
 $gml->printIndex;

=chapter DESCRIPTION
Provides access to the GML definitions specified in XML.  The details
about GML structures can differ, and therefore you should be explicit
which versions you understand and produce.

If you need the <b>most recent</b> version of GML, then you get involved
with the ISO19139 standard.  See CPAN module M<Geo::ISO19139>.

The first releases of this module will not powerful, but hopefully
people contribute.  For instance, an example conversion script between
various versions is very welcome!  It would be nice to help each other.
I will clean-up the implementation, to make it publishable, but do not
have the knowledge about what is needed.

=chapter METHODS

=section Constructors
=c_method new 'READER'|'WRITER'|'RW', OPTIONS

=option   schemas XML::Compile::Cache object
=default  schemas <created internally>

=requires version VERSION|NAMESPACE
Only used when the object is created directly from this base-class.  It
determines which GML syntax is to be used.  Can be a VERSION like "3.1.1"
or a NAMESPACE URI like 'NS_GML_300'.

=option  prefixes ARRAY|HASH
=default prefixes undef
Prefix abbreviations, to be used by cache object.  Which prefixes are
defined depends on the schema version.

=option  allow_undeclared BOOLEAN
=default allow_undeclared <true>
In the optimal case, all types used in your application are declared
during the initiation phase of your program.  This will make it easy
to write a fast daemon application, or transform your program into a
daemon later.  So: "false" would be a good setting.  However, on the moment,
the developer of this module has no idea which types people will use.
Please help me with the specs!

=cut

sub new($@)
{   my ($class, $dir) = (shift, shift);
    (bless {}, $class)->init( {direction => $dir, @_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->{GG_dir} = $args->{direction} or panic "no direction";

    my $version     =  $args->{version}
        or error __x"GML object requires an explicit version";

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"GML version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{GG_version} = $version;    
    my $info    = $info{$version};

    my %prefs   = %{$info->{prefixes}};
    my @xsds    = @{$info->{schemas}};

    # all known schemas need xlink
    $prefs{xlink} = NS_XLINK_1999;
    push @xsds, 'xlink1.0.0/*.xsd';

    my $undecl
      = exists $args->{allow_undeclared} ? $args->{allow_undeclared} : 1;

    my $schemas = $self->{GG_schemas} = $args->{schemas}
     || XML::Compile::Cache->new
         ( prefixes         => \%prefs
         , allow_undeclared => $undecl
         );

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    $schemas->importDefinitions( [map {glob "$xsd/$_"} @xsds] );
    $self;
}

sub declare(@)
{   my $self = shift;

    my $schemas   = $self->schemas;
    my $direction = $self->direction;

    $schemas->declare($direction, $_)
        for @_, @declare_always;

    $self;
}

#---------------------------------

=section Accessors

=method schemas
Returns the internal schema object, type M<XML::Compile::Cache>.

=method version
GML version, for instance '3.2.1'.

=method direction
Returns 'READER', 'WRITER', or 'RW'.
=cut

sub schemas()   {shift->{GG_schemas}}
sub version()   {shift->{GG_version}}
sub direction() {shift->{GG_dir}}

#---------------------------------

=section Helpers

=method template 'PERL'|'XML', TYPE, OPTIONS
See M<XML::Compile::Schema::template()>.  This will create an example
of the data-structure based on GML.  All OPTIONS are passed to the
template generator, the only reason to have this method, is to avoid
the need to collect all the GML XML files yourself.

=example
  use Geo::GML;
  use Geo::GML::Util     qw/NS_GML_321/;
  use XML::Compile::Util qw/pack_type/;
  my $type = pack_type NS_GML_321, 'RectifiedGridCoverage';
  my $gml  = Geo::GML->new(version => NS_GML_321);
  print $gml->template(PERL => $type);
=cut

sub template($$@)
{   my ($self, $format, $type) = (shift, shift, shift);
    $self->schemas->template($format, $type, @_);
}

=method printIndex [FILEHANDLE], OPTIONS
List all the elements which can be produced with the schema.  This will
call M<XML::Compile::Cache::printIndex()> to show (by default) only
the elements and exclude the abstract elements from the list.

The selected FILEHANDLE is the default.  OPTIONS overrule the defaults
which are passed to that C<printIndex()>.
=cut

sub printIndex(@)
{   my $self = shift;
    my $fh   = @_ % 2 ? shift : select;
    $self->schemas->printIndex($fh
      , kinds => 'element', list_abstract => 0, @_); 
}

1;
