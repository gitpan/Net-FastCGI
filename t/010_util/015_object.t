#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 17;

BEGIN {
    use_ok('Net::FastCGI::Util', ':predicate');
}

sub TRUE  () { !!1 };
sub FALSE () { !!0 };

foreach my $test ( undef, -1, [], {} ) {
    my $label = defined($test) ? $test : 'undef';
    is( is_object($test),                   FALSE, qq/is_object($label) = false/ );
    is( is_instance_of($test, 'UNIVERSAL'), FALSE, qq/is_instance_of($label, 'UNIVERSAL') = false/ );
}

{
    my $object = bless( {}, 'main' );
    is( is_object($object),                   TRUE, qq/is_object($object) = true/ );
    is( is_instance_of($object, 'UNIVERSAL'), TRUE, qq/is_instance_of($object, 'UNIVERSAL') = true/ );
    is( is_instance_of($object, 'main'),      TRUE, qq/is_instance_of($object, 'main') = true/ );
    is( is_instance_of($object, 'FooBar'),   FALSE, qq/is_instance_of($object, 'FooBar') = false/ );
}

{
    my $object = bless( {}, '0' );
    is( is_object($object),                   TRUE, qq/is_object($object) = true/ );
    is( is_instance_of($object, 'UNIVERSAL'), TRUE, qq/is_instance_of($object, 'UNIVERSAL') = true/ );
    is( is_instance_of($object, '0'),         TRUE, qq/is_instance_of($object, '0') = true/ );
    is( is_instance_of($object, 'FooBar'),   FALSE, qq/is_instance_of($object, 'FooBar') = false/ );
}
