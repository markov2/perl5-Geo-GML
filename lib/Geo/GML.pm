use warnings;
use strict;

package Geo::GML;
use base 'XML::Compile::Cache';

use Geo::GML::Util;

use Log::Report 'geo-gml', syntax => 'SHORT';
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
                 , schemas  => [ 'gml3.2.1/*.xsd', 'gml3.1.1/smil/*.xsd' ] }
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

The first releases of this module will not powerful, but hopefully
people contribute.  For instance, an example conversion script between
various versions is very welcome!  It would be nice to help each other.
I will clean-up the implementation, to make it publishable, but do not
have the knowledge about what is needed.

=chapter METHODS

=section Constructors
=c_method new 'READER'|'WRITER'|'RW', OPTIONS

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

    $args->{opts_rw} = { @{$args->{opts_rw}} }
        if ref $args->{opts_rw} eq 'ARRAY';
    $args->{opts_rw}{key_rewrite} = 'PREFIXED';
    $args->{opts_rw}{mixed_elements} = 'STRUCTURAL';

    $args->{any_element}         ||= 'ATTEMPT';

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
    my $info    = $info{$version};

    $self->prefixes(xlink => NS_XLINK_1999, %{$info->{prefixes}});

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds    = map {glob "$xsd/$_"}
        @{$info->{schemas} || []}, 'xlink1.0.0/*.xsd';

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

=method template 'PERL'|'XML', TYPE, OPTIONS
See M<XML::Compile::Schema::template()>.  This will create an example
of the data-structure based on GML.  All OPTIONS are passed to the
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

=method printIndex [FILEHANDLE], OPTIONS
List all the elements which can be produced with the schema.  By default,
this only shows the elements and excludes the abstract elements from
the list.  The selected FILEHANDLE is the default to print to.
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
