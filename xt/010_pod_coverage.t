#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval 'use Test::Pod::Coverage';

    if ($@) {
        plan skip_all => 'Needs Test::Pod::Coverage';
    }
}

my @modules = sort grep { !/::(?:PP|XS)$/ } all_modules();

plan tests => scalar(@modules);

foreach my $module ( @modules ) {
    my $params = {};

    if ( $module =~ /^Net::FastCGI::(:?Protocol|Util)$/ ) {
        $params->{coverage_class} = 'Pod::Coverage::ExportOnly';
    }
    elsif ( $module =~ /^Net::FastCGI::(:?Record|Stream)::/ ) {
        $params->{coverage_class} = 'Pod::Coverage::CountParents';
    }

    pod_coverage_ok( $module, $params );
}

