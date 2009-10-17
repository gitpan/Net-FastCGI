#!perl

use bytes;
use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 52;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Record::Stream');
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_request_id
        get_type
        has_content
        is_discrete
        is_management
        is_stream
        new
    ];

    can_ok( 'Net::FastCGI::Record::Stream', @methods );
}

{
    my $record = Net::FastCGI::Record::Stream->new( 0, 0 );
    isa_ok( $record, 'Net::FastCGI::Record' );
    isa_ok( $record, 'Net::FastCGI::Record::Stream' );
}

{
    my @tests = (
        # octets                                                               type  request_id                              content
        [ "\x01\x08\x00\x00\x00\x00\x00\x00",                                     8,          0,                               undef ],
        [ "\x01\x08\xFF\xFF\x00\x00\x00\x00",                                     8,     0xFFFF,                               undef ],
        [ "\x01\x08\x00\x01\x00\x01\x07\x00\x01\x00\x00\x00\x00\x00\x00\x00",     8,          1,                              "\x01" ],
        [ "\x01\x08\x00\x01\x00\x05\x03\x00\x01\x01\x01\x01\x01\x00\x00\x00",     8,          1,              "\x01\x01\x01\x01\x01" ],
        [ "\x01\x08\x00\x01\x00\x08\x00\x00\x01\x01\x01\x01\x01\x01\x01\x01",     8,          1,  "\x01\x01\x01\x01\x01\x01\x01\x01" ],
    );

    foreach my $test ( @tests ) {

        my ( $octets, $type, $request_id, $content ) = @$test;

        my $content_length = defined($content) ? length($content) : 0;
        my $has_content    = $content_length ? 'true' : 'false';

        my $record = Net::FastCGI::Record::Stream->new( $type, $request_id, $content );

        is( $record->get_type,                       $type, qq/get_type = FCGI_DATA/                 );
        is( $record->get_request_id,           $request_id, qq/get_request_id = $request_id/         );
        is( $record->get_content_length,   $content_length, qq/get_content_length = $content_length/ );
        is( $record->has_content,        !!$content_length, qq/has_content = $has_content/           );
        is( $record->is_stream,                        !!1, qq/is_stream = true/                     );
        is( $record->is_discrete,                      !!0, qq/is_discrete = false/                  );

        if ( defined($content) ) {
            is_binary( $record->get_content, $content, qq/get_content/ );
        }
        else {
            is( $record->get_content, $content, qq/get_content/ )
        }

        is_binary( $record->build, $octets, qq/build/ );
    }
}

throws_ok { Net::FastCGI::Record::Stream->new } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::Stream->new( -1,  0, undef ) } qr/^Argument "type"/;
throws_ok { Net::FastCGI::Record::Stream->new(  0, -1, undef ) } qr/^Argument "request_id"/;
throws_ok { Net::FastCGI::Record::Stream->new(  0, 0, "\x00" x (0xFFFF + 1) ) } qr/^Argument "content" must be less than or equal to/;

{
    my @methods = qw[
        build
        get_content
        get_content_length
        has_content
    ];

    my $record = Net::FastCGI::Record::Stream->new( 0, 0 );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

