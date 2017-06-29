#!/usr/bin/env perl
use warnings;
use strict;

use lib 'lib';
use Test::More tests => 4;

use Geo::GML;
use Geo::GML::Util    ':gml2121';

my $gml = Geo::GML->new('RW', version => '2.1.2.1');
isa_ok($gml, 'Geo::GML');
is($gml->version, '2.1.2.1');

use XML::Compile::Util qw/pack_type/;
my $type = pack_type NS_GML_2121, 'MultiPolygon';

my $text = $gml->template(PERL => $type); 
ok(defined $text, 'template generated');
cmp_ok(length $text, '>', 100);

#warn $text;
#$gml->printIndex(\*STDERR);
