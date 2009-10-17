#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 69;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', ':type');
    use_ok('Net::FastCGI::Header');
}

{
    my @methods = qw[
        build
        get_content_length
        get_padding_length
        get_request_id
        get_type
        has_content
        has_padding
        new
        parse
        to_string
    ];

    can_ok( 'Net::FastCGI::Header', @methods );
}

{
    my $header = Net::FastCGI::Header->new( 0, 0, 0, 0 );
    isa_ok( $header, 'Net::FastCGI::Header' );
}

{
    my @tests = (
        # octets                              type  request_id  content_length  padding_length
        ["\x01\x00\x00\x00\x00\x00\x00\x00",     0,          0,              0,              0 ],
        ["\x01\xFF\xFF\xFF\xFF\xFF\xFF\x00",  0xFF,     0xFFFF,         0xFFFF,           0xFF ],
    );

    my $header_test = sub ($$) {
        my ( $header, $test ) = @_;

        my $has_content = $test->[3] ? 'true' : 'false';
        my $has_padding = $test->[4] ? 'true' : 'false';

        is( $header->get_type,             $test->[1], qq/get_type = $test->[1]/           );
        is( $header->get_request_id,       $test->[2], qq/get_request_id = $test->[2]/     );
        is( $header->get_content_length,   $test->[3], qq/get_content_length = $test->[3]/ );
        is( $header->get_padding_length,   $test->[4], qq/get_padding_length = $test->[4]/ );
        is( $header->has_content,        !!$test->[3], qq/has_content = $has_content/      );
        is( $header->has_padding,        !!$test->[4], qq/has_padding = $has_padding/      );

        is_binary( $header->build, $test->[0], qq/build/ );
    };

    foreach my $test ( @tests ) {
        $header_test->( Net::FastCGI::Header->new( @$test[1..4]), $test );
    }

    foreach my $test ( @tests ) {
        $header_test->( Net::FastCGI::Header->parse( $test->[0]), $test );
    }
}

{
    my @tests = (
          # arguments     type  request_id  content_length  padding_length
        [ [ 0, 0       ],    0,          0,              0,              0 ],
        [ [ 1, 1, 8    ],    1,          1,              8,              0 ],
        [ [ 0, 0, 8, 0 ],    0,          0,              8,              0 ],
        [ [ 1, 1, 5    ],    1,          1,              5,              3 ],
        [ [ 0, 0, 5, 5 ],    0,          0,              5,              5 ],
    );

    foreach my $test ( @tests ) {
        my ( $arguments, $type, $request_id, $content_length, $padding_length ) = @$test;

        my $header = Net::FastCGI::Header->new(@$arguments);
        is( $header->get_type,                       $type, qq/get_type = $type/                     );
        is( $header->get_request_id,           $request_id, qq/get_request_id = $request_id/         );
        is( $header->get_content_length,   $content_length, qq/get_content_length = $content_length/ );
        is( $header->get_padding_length,   $padding_length, qq/get_padding_length = $padding_length/ );
    }
}

{
    my $header = Net::FastCGI::Header->new( FCGI_BEGIN_REQUEST, 1, 8, 0 );
    like($header->to_string, qr/^FCGI_Header type: FCGI_BEGIN_REQUEST, request_id: 1, content_length: 8, padding_length: 0/);
}

throws_ok { Net::FastCGI::Header->new                   } qr/^Usage: /;
throws_ok { Net::FastCGI::Header->new( (0) x 1 )        } qr/^Usage: /;
throws_ok { Net::FastCGI::Header->new( (0) x 5 )        } qr/^Usage: /;
throws_ok { Net::FastCGI::Header->new( -1,  0,  0,  0 ) } qr/^Argument "type"/;
throws_ok { Net::FastCGI::Header->new(  0, -1,  0,  0 ) } qr/^Argument "request_id"/;
throws_ok { Net::FastCGI::Header->new(  0,  0, -1,  0 ) } qr/^Argument "content_length"/;
throws_ok { Net::FastCGI::Header->new(  0,  0,  0, -1 ) } qr/^Argument "padding_length"/;
throws_ok { Net::FastCGI::Header->parse                 } qr/^Usage: /;

{
    my @methods = qw[
        build
        get_content_length
        get_padding_length
        get_request_id
        get_type
        has_content
        has_padding
        to_string
    ];

    my $record = Net::FastCGI::Header->new( 0, 0, 0, 0 );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

