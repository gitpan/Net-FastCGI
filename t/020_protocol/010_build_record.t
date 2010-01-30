#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 8;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_record ]);
}

my @tests = (
    # octets                                                               type  request_id                              content
    [ "\x01\x00\x00\x00\x00\x00\x00\x00",                                     0,          0,                               undef ],
    [ "\x01\xFF\xFF\xFF\x00\x00\x00\x00",                                  0xFF,     0xFFFF,                               undef ],
    [ "\x01\x01\x00\x01\x00\x01\x07\x00\x01\x00\x00\x00\x00\x00\x00\x00",     1,          1,                              "\x01" ],
    [ "\x01\x01\x00\x01\x00\x05\x03\x00\x01\x01\x01\x01\x01\x00\x00\x00",     1,          1,              "\x01\x01\x01\x01\x01" ],
    [ "\x01\x01\x00\x01\x00\x08\x00\x00\x01\x01\x01\x01\x01\x01\x01\x01",     1,          1,  "\x01\x01\x01\x01\x01\x01\x01\x01" ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_record(@$test[1..3]);
    is_binary($got, $expected, 'build_record()');
}

throws_ok { build_record( 0, 0, "\x00" x (0xFFFF + 1) ) } qr/^Invalid Argument: 'content' must be less than or equal to/;

throws_ok { build_record() } qr/^Usage: /;

