#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 9;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_params
                                         parse_params ]);
}

my @tests = (
    # octets                                                  params                         length
    [ "\x00\x00",                                          { '' => '' },                          2 ],
    [ "\x01\x01\x31\x31",                                  {  1 =>  1 },                          4 ],
    [ "\x01\x01\x41\x42\x01\x01\x43\x44\x01\x01\x45\x46",  {  A => 'B', C => 'D', E => 'F' },    12 ]
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_params($test->[1]);
    is_binary($got, $expected, 'build_params()');
}

foreach my $test (@tests) {
    my $expected = $test->[1];
    my $got      = parse_params($test->[0]);
    is_deeply($got, $expected, 'parse_params()');
}

throws_ok { build_params() } qr/^Usage: /;
throws_ok { parse_params() } qr/^Usage: /;
