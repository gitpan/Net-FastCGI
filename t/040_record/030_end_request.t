#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 59;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[:type :protocol_status]);
    use_ok('Net::FastCGI::Record::EndRequest');
}

{
    my @methods = qw[
        build
        get_application_status
        get_content
        get_content_length
        get_protocol_status
        get_request_id
        get_type
        has_content
        is_discrete
        is_management
        is_stream
        new
        parse
        to_string
    ];

    can_ok( 'Net::FastCGI::Record::EndRequest', @methods );
}

{
    my $record = Net::FastCGI::Record::EndRequest->new( 0, 0, 0 );
    isa_ok( $record, 'Net::FastCGI::Record' );
    isa_ok( $record, 'Net::FastCGI::Record::EndRequest' );
}

{
    my @tests = (
        # octets                                                               request_id  application_status  protocol_status
        [ "\x01\x03\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",           0,                  0,               0 ],
        [ "\x01\x03\xFF\xFF\x00\x08\x00\x00\xFF\xFF\xFF\xFF\xFF\x00\x00\x00",      0xFFFF,         0xFFFFFFFF,            0xFF ],
    );

    my $record_test = sub ($$) {
        my ( $record, $test ) = @_;
        is( $record->get_type,            FCGI_END_REQUEST, qq/get_type = FCGI_END_REQUEST/         );
        is( $record->get_request_id,            $test->[1], qq/get_request_id = $test->[1]/         );
        is( $record->get_content_length,                 8, qq/get_content_length = 8/              );
        is( $record->has_content,                      !!1, qq/has_content = true/                  );
        is( $record->is_stream,                        !!0, qq/is_stream = false/                   );
        is( $record->is_discrete,                      !!1, qq/is_discrete = true/                  );
        is( $record->get_application_status,    $test->[2], qq/get_application_status = $test->[2]/ );
        is( $record->get_protocol_status,       $test->[3], qq/get_protocol_status = $test->[3]/    );

        is_binary( $record->get_content,  substr( $test->[0], 8, 8 ), qq/get_content/ );
        is_binary( $record->build,                        $test->[0], qq/build/       );
    };

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::EndRequest->new(@$test[1..3]);
        $record_test->( $record, $test );
    }

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::EndRequest->parse( $test->[1], substr( $test->[0], 8, 8 ));
        $record_test->( $record, $test );
    }
}

{
    my $record = Net::FastCGI::Record::EndRequest->new( 1, 0, FCGI_REQUEST_COMPLETE );
    like(
        $record->to_string,
        qr/^type: FCGI_END_REQUEST, .* application_status: 0x0000, protocol_status: FCGI_REQUEST_COMPLETE/
    );
}

throws_ok { Net::FastCGI::Record::EndRequest->new               } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::EndRequest->new( -1,  0,  0 ) } qr/^Argument "request_id"/;
throws_ok { Net::FastCGI::Record::EndRequest->new(  0, -1,  0 ) } qr/^Argument "application_status"/;
throws_ok { Net::FastCGI::Record::EndRequest->new(  0,  0, -1 ) } qr/^Argument "protocol_status"/;
throws_ok { Net::FastCGI::Record::EndRequest->parse             } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::EndRequest->parse( 0, undef ) } qr/^Argument "octets"/;

{
    my @methods = qw[
        build
        get_application_status
        get_content
        get_content_length
        get_protocol_status
        has_content
        to_string
    ];

    my $record = Net::FastCGI::Record::EndRequest->new( 0, 0, 0 );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

