#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 30;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_params_pair
                                         parse_params_pair
                                         compute_params_pair_length ]);
}

my @tests = (
    # octets                                                 name,       value   length
    [ "\x00\x00",                                           undef,       undef,       2 ],
    [ "\x00\x00",                                              '',          '',       2 ],
    [ "\x01\x01\x31\x31",                                       1,           1,       4 ],
    [ "\x01\x7F\x46" . "\x42" x 127,                          'F',   'B' x 127,     130 ],
    [ "\x7F\x01" . "\x46" x 127 . "\x42",               'F' x 127,         'B',     130 ],
    [ "\x01\x80\x00\x00\x80\x46" . "\x42" x 128,              'F',   'B' x 128,     134 ],
    [ "\x80\x00\x00\x80\x01" . "\x46" x 128 . "\x42",   'F' x 128,         'B',     134 ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_params_pair(@$test[1..2]);
    is_binary($got, $expected, 'build_params_pair()');
}

foreach my $test (@tests) {
    my @expected = map { defined($_) ? $_ : '' } @$test[1..3];
    my @got      = parse_params_pair($test->[0]);
    is_deeply(\@got, \@expected, 'parse_params_pair()');
}

foreach my $test (@tests) {
    my $expected = $test->[3];
    my $got      = compute_params_pair_length(@$test[1..2]);
    is($got, $expected, 'compute_params_pair_length()');
}

throws_ok { build_params_pair() } qr/^Usage: /;

throws_ok { parse_params_pair() } qr/^Usage: /;

throws_ok { parse_params_pair("") } qr/^Argument "octets" must be greater than or equal to/;

throws_ok { parse_params_pair("\x00\x00", -1) } qr/^Argument "offset" is not/;

throws_ok { parse_params_pair("\x00\x00",  4) } qr/^Argument "offset" is outside/;

throws_ok { parse_params_pair("\x01\x01\x01\x01", 2) } qr/^Unexpected end of octets/;

throws_ok { parse_params_pair("\x00\x01\x01\x01", 1) } qr/^Unexpected end of octets/;

throws_ok { compute_params_pair_length() } qr/^Usage: /;
