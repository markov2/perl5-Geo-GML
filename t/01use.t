#!/usr/bin/perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 12;

# The versions of the following packages are reported to help understanding
# the environment in which the tests are run.  This is certainly not a
# full list of all installed modules.
my @show_versions =
 qw/Test::More
    XML::Compile
    XML::Compile::Cache
   /;

foreach my $package (@show_versions)
{   eval "require $package";

    my $report
      = !$@                    ? "version ". ($package->VERSION || 'unknown')
      : $@ =~ m/^Can't locate/ ? "not installed"
      : "reports error";

    warn "$package $report\n";
}

use_ok('Geo::GML');
use_ok('Geo::GML::Util');
use_ok('Geo::GML::2_1_2_0');
use_ok('Geo::GML::2_1_2_1');
use_ok('Geo::GML::3_0_0');
use_ok('Geo::GML::3_0_1');
use_ok('Geo::GML::3_1_0');
use_ok('Geo::GML::3_1_1');
use_ok('Geo::GML::3_2_1');
use_ok('Geo::GML::2_0_0');
use_ok('Geo::GML::2_1_1');
use_ok('Geo::GML::2_1_2');
