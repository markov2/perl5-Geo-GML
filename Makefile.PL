use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile
 ( NAME	 	=> 'Geo::GML'
 , VERSION	=> '0.10'
 , PREREQ_PM    =>
   { XML::Compile              => 0.84
   , XML::Compile::Tester      => 0.02
   , XML::Compile::Cache       => '0.10'
   , Log::Report               => 0.19

   , Test::More                => 0.54
   , Test::Pod                 => '1.00'
   }

 , EXE_FILES    => []
 , AUTHOR       => 'Mark Overmeer'
 , ABSTRACT     => 'Process Geography Markup Language'
 , LICENSE      => 'perl'
 );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/geo-gml/raw
DISTDIR         = ../public_html/geo-gml/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/geo/
PODTAIL		= ../Geo-shared-podtail
__POSTAMBLE
