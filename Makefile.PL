use ExtUtils::MakeMaker;

use 5.010;

my $version = '0.19';

my %prereq  =
  ( XML::Compile         => '1.59'
  , XML::Compile::Cache  => '1.05'
  , Log::Report          => '1.25'
 
  , Test::More           => '0.54'
  );

# Upgrade Geo::Point only if installed, to avoid difficult indirect
# installation of Geo::Proj4
eval "require Geo::Point";
if($@ && $@ =~ m/^Can't locate /)
{   print "optional Geo::Point is not installed\n";
}
else
{   $prereq{'Geo::Point'} = '0.90';
}

WriteMakefile
  ( NAME      => 'Geo::GML'
  , VERSION   => $version
  , PREREQ_PM => \%prereq
  , EXE_FILES => []
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'process Geography Markup Language (GML)'
  , LICENSE   => 'perl'

  , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
          { repository =>
              { type => 'git'
              , url  => 'https://github.com/markov2/perl5-Geo-GML.git'
              , web  => 'https://github.com/markov2/perl5-Geo-GML'
              }
          , homepage => 'http://perl.overmeer.net/CPAN/'
          , license  => [ 'http://dev.perl.org/licenses/' ]
          }
      }
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-gml/raw
DISTDIR         = ../public_html/geo-gml/source
EXTENDS         = ../../perl/XMLCache:../../perl/XMLCompile

# for POD
FIRST_YEAR      = 2008-2009,2018
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/
__POSTAMBLE
