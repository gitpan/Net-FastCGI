#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 7;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_begin_request_record ]);
}

my @tests = (
    # octets                                                               request_id    role  flags
    [ "\x01\x01\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",           0,      0,     0 ],
    [ "\x01\x01\xFF\xFF\x00\x08\x00\x00\xFF\xFF\xFF\x00\x00\x00\x00\x00",      0xFFFF, 0xFFFF,  0xFF ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_begin_request_record(@$test[1..3]);
    is_binary($got, $expected, 'build_begin_request_record()');
}

throws_ok { build_begin_request_record() } qr/^Usage: /;

throws_ok { build_begin_request_record( -1, 0, 0 ) } qr/^Argument "request_id"/;

throws_ok { build_begin_request_record( 0, -1, 0 ) } qr/^Argument "role"/;

throws_ok { build_begin_request_record( 0, 0, -1 ) } qr/^Argument "flags"/;
