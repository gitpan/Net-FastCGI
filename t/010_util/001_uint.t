#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 67;

BEGIN {
    use_ok('Net::FastCGI::Util', ':predicate');
}

sub TRUE  () { !!1 };
sub FALSE () { !!0 };

foreach my $test ( undef, -1, -0xFF, '01', 1.1 ) {
    my $label = defined($test) ? $test : 'undef';
    is(   is_uint($test), FALSE,   qq/is_uint($label) = false/);
    is(  is_uint8($test), FALSE,  qq/is_uint8($label) = false/);
    is( is_uint16($test), FALSE, qq/is_uint16($label) = false/);
    is( is_uint31($test), FALSE, qq/is_uint31($label) = false/);
    is( is_uint32($test), FALSE, qq/is_uint32($label) = false/);
}

foreach my $size ( 8, 16, 24, 31, 32 ) {
    my $uint = ( 1 << ( $size - 1 ) ) * 2 - 1;
    is(   is_uint($uint),                TRUE,    qq/is_uint($uint)/ );
    is(  is_uint8($uint), ( $uint >>  8 ) == 0,  qq/is_uint8($uint)/ );
    is( is_uint16($uint), ( $uint >> 16 ) == 0, qq/is_uint16($uint)/ );
    is( is_uint31($uint), ( $uint >> 31 ) == 0, qq/is_uint31($uint)/ );
    is( is_uint32($uint),                TRUE,  qq/is_uint32($uint)/ );
}

foreach my $test ( '0', '1', '255' ) {
    is(   is_uint($test), TRUE,   qq/is_uint($test) = true/ );
    is(  is_uint8($test), TRUE,  qq/is_uint8($test) = true/ );
    is( is_uint16($test), TRUE, qq/is_uint16($test) = true/ );
    is( is_uint31($test), TRUE, qq/is_uint31($test) = true/ );
    is( is_uint32($test), TRUE, qq/is_uint32($test) = true/ );
}

{
    my $uint = 4294967296;
    is( is_uint32($uint), FALSE, qq/is_uint32($uint)/ );
}
