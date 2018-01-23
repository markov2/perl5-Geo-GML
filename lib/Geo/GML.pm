# This code is part of distribution Geo::GML.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Geo::GML;
use base 'XML::Compile::Cache';

use warnings;
use strict;

use Geo::GML::Util;

use Log::Report 'geo-gml', syntax => 'SHORT';
use XML::Compile::Util  qw/unpack_type pack_type type_of_node SCHEMA2001/;
use File::Glob          qw/bsd_glob/;

# map namespace always to the newest implementation of the protocol
my %ns2version =
  ( &NS_GML    => '3.1.1'
  , &NS_GML_32 => '3.2.1'
  );

# list all available versions
my %info =
  ( '2.1.2'   => { prefixes => {gml => NS_GML_212}
                 , schemas  => [ 'gml-2.1.2/*.xsd' ] }
  , '3.0.0'   => { prefixes => {gml => NS_GML_300, smil => NS_SMIL_20}
                 , schemas  => [ 'gml-3.0.0/*/*.xsd' ] }
  , '3.0.1'   => { prefixes => {gml => NS_GML_301, smil => NS_SMIL_20}
                 , schemas  => [ 'gml-3.0.1/*/*.xsd' ] }
  , '3.1.0'   => { prefixes => {gml => NS_GML_310, smil => NS_SMIL_20}
                 , schemas  => [ 'gml-3.1.0/*/*.xsd' ] }
  , '3.1.1'   => { prefixes => {gml => NS_GML_311, smil => NS_SMIL_20
                               ,gmlsf => NS_GML_311_SF}
                 , schemas  => [ 'gml-3.1.1/{base,smil,xlink}/*.xsd'
                               , 'gml3.1.1/profile/*/*/*.xsd' ] }
  , '3.2.1'   => { prefixes => {gml => NS_GML_321, smil => NS_SMIL_20 }
                 , schemas  => [ 'gml-3.2.1/*.xsd', 'gml-3.1.1/smil/*.xsd' ] }
  );

# This list must be extended, but I do not know what people need.
my @declare_always =
    qw/gml:TopoSurface/;

# for Geo::EOP and other stripped-down GML versions
sub _register_gml_version($$) { $info{$_[1]} = $_[2] }

=chapter NAME
Geo::GML - Geography Markup Language processing

=chapter SYNOPSIS
 use Geo::GML ':gml321';

 my $gml = Geo::GML->new('READER', version => '3.2.1');

 # see XML::Compile::Cache on how to use readers and writers
 my $data = $gml->reader("gml:GridCoverage")->($xmlmsg);
 my $xml  = $gml->writer($sometype)->($doc, $perldata);

 # or without help of the cache, XML::Compile::Schema
 my $r    = $gml->compile(READER => $sometype);
 my $data = $r->($xml);

 # super simple
 my ($type, $data) = Geo::GML->from('data.xml');

 # overview (large) on all defined elements
 $gml->printIndex;

 # To discover the perl datastructures to be passed
 print $gml->template("gml:Surface");

 # autoloaded logic to convert Geo::Point into GML
 $data->{...somewhere...} = $gml->GPtoGML($objects);

=chapter DESCRIPTION
Provides access to the GML definitions specified in XML.  The details
about GML structures can differ, and therefore you should be explicit
which versions you understand and produce.

If you need the <b>most recent</b> version of GML, then you get involved
with the ISO19139 standard.  See CPAN module M<Geo::ISO19139>.

B<When you need GML3.3 features, then please contact me>

=chapter METHODS

=section Constructors

=c_method new 'READER'|'WRITER'|'RW', %options

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

=default any_element C<ATTEMPT>
All C<any> elements will be ATTEMPTed to be processed at run-time
by default.

=default opts_rw <some>
The GML specification will require PREFIXED key rewrite, because the
complexity of namespaces is enormous.  Besides, mixed elements are
processed as STRUCTURAL by default (mixed in texts ignored).

=cut

sub new($@)
{   my ($class, $dir) = (shift, shift);
    $class->SUPER::new(direction => $dir, @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{allow_undeclared} = 1
        unless exists $args->{allow_undeclared};

    $args->{opts_rw} = +{ @{$args->{opts_rw}} }
        if ref $args->{opts_rw} eq 'ARRAY';
    $args->{opts_rw}{key_rewrite}    = 'PREFIXED';
    $args->{opts_rw}{mixed_elements} = 'STRUCTURAL';

    $args->{any_element}           ||= 'ATTEMPT';

    $self->SUPER::init($args);

    $self->{GG_dir} = $args->{direction} or panic "no direction";

    my $version     =  $args->{version}
        or error __x"GML object requires an explicit version";

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"GML version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{GG_version} = $version;    
    my $info = $info{$version};

    $self->addPrefixes
		( xlink => NS_XLINK_1999
		, xsd   => SCHEMA2001,
		, %{$info->{prefixes}}
		);

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds = map bsd_glob("$xsd/$_")
      , @{$info->{schemas} || []}
      , 'xlink-1.1/*.xsd'
      , 'xml-1999/*.xsd';

    $self->importDefinitions(\@xsds);
    $self;
}

sub declare(@)
{   my $self = shift;

    my $direction = $self->direction;

    $self->declare($direction, $_)
        for @_, @declare_always;

    $self;
}

=ci_method from $xmldata, %options
Read a GML structure from a data source, which can be anything acceptable
by M<dataToXML()>: a M<XML::LibXML::Element>, XML as string or ref-string,
filename, filehandle or known namespace.

Returned is the product (the type of the root node) and the parsed
data-structure.  The EOP version used for decoding is autodetected,
unless specified.

See F<examples/read_gml.pl>

=example
  my ($type, $data) = Geo::GML->from('data.xml');

=cut

sub from($@)
{   my ($thing, $data, %args) = @_;
	my $class = ref $thing || $thing;

    my $xml   = XML::Compile->dataToXML($data);
    my $top   = type_of_node $xml;
    my $ns    = (unpack_type $top)[0];

    my $version = $ns2version{$ns}
        or error __x"unknown GML version with namespace {ns}", ns => $ns;

    my $self = $class->new('READER', version => $version);
    my $r   = $self->reader($top, %args)
        or error __x"root node `{top}' not recognized", top => $top;

    ($top, $r->($xml));
}

#---------------------------------

=section Accessors

=method version 
GML version, for instance '3.2.1'.

=method direction 
Returns 'READER', 'WRITER', or 'RW'.
=cut

sub version()   {shift->{GG_version}}
sub direction() {shift->{GG_dir}}

#---------------------------------

=section Compilers

=method template 'PERL'|'XML', $type, %options
See M<XML::Compile::Schema::template()>.  This will create an example
of the data-structure based on GML.  All %options are passed to the
template generator, the only reason to have this method, is to avoid
the need to collect all the GML XML files yourself.

=example
  use Geo::GML;
  use Geo::GML::Util     qw/NS_GML_321/;
  use XML::Compile::Util qw/pack_type/;
  my $gml   = Geo::GML->new(version => NS_GML_321);

  # to simplify the output, reducing often available large blocks
  my @types = qw/gml:MetaDataPropertyType gml:StringOrRefType
     gml:ReferenceType/;
  my %hook  = (type => \@collapse_types, replace => 'COLLAPSE');

  # generate the data-structure
  my $type  = 'gml:RectifiedGridCoverage';  # any element name
  print $gml->template(PERL => $type, hook => \%hook);
=cut

# just added as example, implemented in super-class

#------------------

=section Helpers

=section Administration

=method printIndex [$fh], %options
List all the elements which can be produced with the schema.  By default,
this only shows the elements and excludes the abstract elements from
the list.  The selected $fh is the default to print to.
=cut

sub printIndex(@)
{   my $self = shift;
    my $fh   = @_ % 2 ? shift : select;
    $self->SUPER::printIndex($fh
      , kinds => 'element', list_abstract => 0, @_); 
}

our $AUTOLOAD;
sub AUTOLOAD(@)
{   my $self = shift;
    my $call = $AUTOLOAD;
    return if $call =~ m/::DESTROY$/;
    my ($pkg, $method) = $call =~ m/(.+)\:\:([^:]+)$/;
    $method eq 'GPtoGML'
        or error __x"method {name} not implemented", name => $call;
    eval "require Geo::GML::GeoPoint";
    panic $@ if $@;
    $self->$call(@_);
}

1;
