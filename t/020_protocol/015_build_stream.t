#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 12;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Protocol', qw[ build_stream ]);
}

sub TRUE  () { !!1 }
sub FALSE () { !!0 }

my @tests = (
    # expected,                             type, request_id, content, terminate
    [ "",                                      1,          1,      '',         0 ],
    [ "",                                      1,          1,   undef,         0 ],
    [ "\x01\x01\x00\x01\x00\x00\x00\x00",      1,          1,      '',         1 ],
    [ "\x01\x01\x00\x01\x00\x00\x00\x00",      1,          1,   undef,         1 ],

    [ "\x01\x01\x00\x01\x00\x03\x05\x00"
    . "FOO\x00\x00\x00\x00\x00",               1,          1,   'FOO',         0 ],

    [ "\x01\x01\x00\x01\x00\x03\x05\x00"
    . "FOO\x00\x00\x00\x00\x00"
    . "\x01\x01\x00\x01\x00\x00\x00\x00",      1,          1,   'FOO',         1 ],
);

foreach my $test (@tests) {
    my $expected = $test->[0];
    my $got      = build_stream(@$test[1..4]);
    is_binary($got, $expected, 'build_stream()');
}

{
    my $header  = "\x01\x01\x00\x01\x1F\xF8\x00\x00";
    my $content = "x" x 8184;
    my $trailer = "\x01\x01\x00\x01\x00\x00\x00\x00";

    {
        my $expected = $header . $content;
        my $got      = build_stream(1,1, $content);
        is_binary($got, $expected, 'build_stream(content_length: 8184 terminate:false)');
    }

    {
        my $expected = $header . $content . $trailer;
        my $got      = build_stream(1,1, $content, 1);
        is_binary($got, $expected, 'build_stream(content_length: 8184 terminate:true)');
    }
}

{
    my $records = "\x01\x01\x00\x01\x1F\xF8\x00\x00" #  H1
                . "x" x 8184                         #  C1
                . "\x01\x01\x00\x01\x00\x08\x00\x00" #  H2
                . "x" x 8                            #  C2
                ;
    my $content = "x" x 8192;
    my $trailer = "\x01\x01\x00\x01\x00\x00\x00\x00";

    {
        my $expected = $records;
        my $got      = build_stream(1,1, $content);
        is_binary($got, $records, 'build_stream(content_length: 8192 terminate:false)');
    }

    {
        my $expected = $records . $trailer;
        my $got      = build_stream(1,1, $content, 1);
        is_binary($got, $expected, 'build_stream(content_length: 8192 terminate:true)');
    }
}

throws_ok { build_stream() } qr/^Usage: /;

