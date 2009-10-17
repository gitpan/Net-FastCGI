#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 46;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_params_pair_header
                                         parse_params_pair_header
                                         compute_params_pair_header_length ]);
}

my @tests = (
    # octets                              name_length,  value_length  length
    [ "\x00\x00",                                   0,             0,      2 ],
    [ "\x01\x00",                                   1,             0,      2 ],
    [ "\x7F\x7F",                                 127,           127,      2 ],
    [ "\x7F\xFF\xFF\xFF\xFF",                     127,    0x7FFFFFFF,      5 ],
    [ "\xFF\xFF\xFF\xFF\x7F",              0x7FFFFFFF,           127,      5 ],
    [ "\x80\x00\x00\x80\x80\x00\x00\x80",         128,           128,      8 ],
    [ "\x80\x00\xFF\xFF\x80\x00\xFF\xFF",      0xFFFF,        0xFFFF,      8 ],
    [ "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF",  0x7FFFFFFF,    0x7FFFFFFF,      8 ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_params_pair_header(@$test[1..2]);
    is_binary($got, $expected, 'build_params_pair_header()');
}

foreach my $test (@tests) {
    my @expected = @$test[1..3];
    my @got      = parse_params_pair_header($test->[0]);
    is_deeply(\@got, \@expected, 'parse_params_pair_header()');
}

foreach my $test (@tests) {
    my $expected = $test->[3];
    my $got      = compute_params_pair_header_length(@$test[1..2]);
    is($got, $expected, 'compute_params_pair_header_length()');
}

foreach my $bad ( undef, -1, 0xFFFFFFFF ) {

    throws_ok { build_params_pair_header($bad, 0) } qr/^Argument "name_length"/;

    throws_ok { build_params_pair_header(0, $bad) } qr/^Argument "value_length"/;

    throws_ok { compute_params_pair_header_length($bad, 0) } qr/^Argument "name_length"/;

    throws_ok { compute_params_pair_header_length(0, $bad) } qr/^Argument "value_length"/;
}

throws_ok { build_params_pair_header() } qr/^Usage: /;

throws_ok { parse_params_pair_header() } qr/^Usage: /;

throws_ok { parse_params_pair_header("") } qr/^Argument "octets" must be greater than or equal to/;

throws_ok { parse_params_pair_header("\x00\x00", -1) } qr/^Argument "offset" is not/;

throws_ok { parse_params_pair_header("\x00\x00",  4) } qr/^Argument "offset" is outside/;

throws_ok { parse_params_pair_header("\x00\x00",  2) } qr/^Unexpected end of octets/;

throws_ok { parse_params_pair_header("\x00\x80\x00",  1) } qr/^Unexpected end of octets/;

throws_ok { parse_params_pair_header("\x00\x80\x00",  0) } qr/^Unexpected end of octets/;

throws_ok { compute_params_pair_header_length() } qr/^Usage: /;
