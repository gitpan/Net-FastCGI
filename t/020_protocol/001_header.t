#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 14;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_header
                                         parse_header ]);
}

my @tests = (
    # octets                              type  request_id  content_length  padding_length
    ["\x01\x00\x00\x00\x00\x00\x00\x00",     0,          0,              0,              0 ],
    ["\x01\xFF\xFF\xFF\xFF\xFF\xFF\x00",  0xFF,     0xFFFF,         0xFFFF,           0xFF ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_header(@$test[1..4]);
    is_binary($got, $expected, 'build_header()');
}

foreach my $test (@tests) {
    my @expected = @$test[1..4];
    my @got      = parse_header($test->[0]);
    is_deeply(\@got, \@expected, "parse_header()");
}

throws_ok { build_header() } qr/^Usage: /;

throws_ok { build_header( -1,  0,  0,  0 ) } qr/^Argument "type" is not an unsigned 8-bit integer/;

throws_ok { build_header(  0, -1,  0,  0 ) } qr/^Argument "request_id" is not an unsigned 16-bit integer/;

throws_ok { build_header(  0,  0, -1,  0 ) } qr/^Argument "content_length" is not an unsigned 16-bit integer/;

throws_ok { build_header(  0,  0,  0, -1 ) } qr/^Argument "padding_length" is not an unsigned 8-bit integer/;

throws_ok { parse_header() } qr/^Usage: /;

throws_ok { parse_header("") } qr/^Argument "octets" must be greater than or equal to/;

throws_ok { parse_header("\x00\x00\x00\x00\x00\x00\x00\x00") } qr/^Unsupported FastCGI version: 0/;

throws_ok { parse_header("\xFF\x00\x00\x00\x00\x00\x00\x00") } qr/^Unsupported FastCGI version: 255/;

