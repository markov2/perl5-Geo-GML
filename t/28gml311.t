#!/usr/bin/perl
use warnings;
use strict;

#use Log::Report mode => 3;
use lib 'lib';
use Test::More tests => 4;

use Geo::GML;
use Geo::GML::Util    ':gml311';

my $gml = Geo::GML->new('RW', version => '3.1.1');
isa_ok($gml, 'Geo::GML');
is($gml->version, '3.1.1');

use XML::Compile::Util qw/pack_type/;
my $type = pack_type NS_GML_311, 'RectifiedGridCoverage';

my $text = $gml->template(PERL => $type); 
ok(defined $text, 'template generated');
cmp_ok(length $text, '>', 100);

#warn $text;
#$gml->printIndex(\*STDERR);
