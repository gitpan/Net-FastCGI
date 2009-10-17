#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 14;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_padding
                                         compute_padding_length ]);
}

is_binary( build_padding(0),           '', 'build_padding(0)' );
is_binary( build_padding(1),       "\x00", 'build_padding(1)' );
is_binary( build_padding(10), "\x00" x 10, 'build_padding(10)' );

is( compute_padding_length(0), 0, 'compute_padding_length(0) = 0' );
is( compute_padding_length(1), 7, 'compute_padding_length(5) = 7' );
is( compute_padding_length(5), 3, 'compute_padding_length(5) = 3' );
is( compute_padding_length(8), 0, 'compute_padding_length(8) = 0' );

throws_ok { build_padding() } qr/^Usage: /;

throws_ok { build_padding(-1) } qr/^Argument "padding_length"/;

throws_ok { build_padding(0xFFFF) } qr/^Argument "padding_length"/;

throws_ok { compute_padding_length() } qr/^Usage: /;

throws_ok { compute_padding_length(-1) } qr/^Argument "content_length"/;

throws_ok { compute_padding_length(0xFFFFFFFF) } qr/^Argument "content_length"/;
