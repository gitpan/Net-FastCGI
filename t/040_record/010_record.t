#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 40;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[:type FCGI_NULL_REQUEST_ID]);
    use_ok('Net::FastCGI::Record');
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
        to_string
    ];

    can_ok( 'Net::FastCGI::Record', @methods );
}

{
    my $record = Net::FastCGI::Record->new( 0, 0 );
    isa_ok( $record, 'Net::FastCGI::Record' );
}

{
    my @tests = (
        # octets                                type  request_id
        [ "\x01\x00\x00\x00\x00\x00\x00\x00",      0,          0 ],
        [ "\x01\xFF\xFF\xFF\x00\x00\x00\x00",   0xFF,     0xFFFF ],
    );

    foreach my $test ( @tests ) {

        my ( $octets, $type, $request_id ) = @$test;

        my $record = Net::FastCGI::Record->new( $type, $request_id );
        is( $record->get_type,                $type, qq/get_type = $type/             );
        is( $record->get_request_id,    $request_id, qq/get_request_id = $request_id/ );
        is( $record->get_content,             undef, qq/get_content = undef/          );
        is( $record->get_content_length,          0, qq/get_content_length = 0/       );
        is( $record->has_content,               !!0, qq/has_content = false/          );
        is( $record->is_stream,                 !!0, qq/is_stream = false/            );
        is( $record->is_discrete,               !!0, qq/is_discrete = false/          );
        is_binary($record->build,           $octets, qq/build/                        );
    }
}

{
    foreach my $request_id ( 0, 1, 1000 ) {
        my $record = Net::FastCGI::Record->new( 0, $request_id );
        is( $record->get_request_id, $request_id, qq/get_request_id = $request_id/ );

        if ( $request_id == FCGI_NULL_REQUEST_ID ) {
            is( $record->is_management, !!1, qq/is_management = true/ );
        }
        else {
            is( $record->is_management, !!0, qq/is_management = false/ );
        }
    }
}

{
    my $record = Net::FastCGI::Record->new( FCGI_ABORT_REQUEST, 1);
    like($record->to_string, qr/^type: FCGI_ABORT_REQUEST, request_id: 1, content_length: 0/);
}

throws_ok { Net::FastCGI::Record->new } qr/^Usage: /;
throws_ok { Net::FastCGI::Record->new( -1,  0 ) } qr/^Argument "type"/;
throws_ok { Net::FastCGI::Record->new(  0, -1 ) } qr/^Argument "request_id"/;

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
        to_string
    ];

    my $record = Net::FastCGI::Record->new( 0, 0 );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

