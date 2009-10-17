#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 52;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[ :type FCGI_NULL_REQUEST_ID]);
    use_ok('Net::FastCGI::Record::UnknownType');
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_request_id
        get_type
        get_unknown_type
        has_content
        is_discrete
        is_management
        is_stream
        new
        parse
        to_string
    ];

    can_ok( 'Net::FastCGI::Record::UnknownType', @methods );
}

{
    my $record = Net::FastCGI::Record::UnknownType->new(0);
    isa_ok( $record, 'Net::FastCGI::Record' );
    isa_ok( $record, 'Net::FastCGI::Record::UnknownType' );
}

{
    my @tests = (
        # octets                                                              unknown_type
        [ "\x01\x0B\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",            0 ],
        [ "\x01\x0B\x00\x00\x00\x08\x00\x00\xFF\x00\x00\x00\x00\x00\x00\x00",         0xFF ],
    );

    my $record_test = sub ($$) {
        my ( $record, $test ) = @_;
        is( $record->get_type,              FCGI_UNKNOWN_TYPE, qq/get_type = FCGI_END_REQUEST/           );
        is( $record->get_request_id,     FCGI_NULL_REQUEST_ID, qq/get_request_id = FCGI_NULL_REQUEST_ID/ );
        is( $record->get_content_length,                    8, qq/get_content_length = 8/                );
        is( $record->has_content,                         !!1, qq/has_content = true/                    );
        is( $record->is_stream,                           !!0, qq/is_stream = false/                     );
        is( $record->is_discrete,                         !!1, qq/is_discrete = true/                    );
        is( $record->get_unknown_type,             $test->[1], qq/get_unknown_type = $test->[1]/         );

        my $content = substr( $test->[0], 8, 8 );
        is_binary( $record->get_content,   $content, qq/get_content/ );
        is_binary( $record->build,       $test->[0], qq/build/       );
    };

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::UnknownType->new($test->[1]);
        $record_test->( $record, $test );
    }

    foreach my $test ( @tests ) {
        my $octets = substr( $test->[0], 8, 8 );
        my $record = Net::FastCGI::Record::UnknownType->parse($octets);
        $record_test->( $record, $test );
    }
}

throws_ok { Net::FastCGI::Record::UnknownType->new          } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::UnknownType->new(-1)      } qr/^Argument "unknown_type"/;
throws_ok { Net::FastCGI::Record::UnknownType->parse        } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::UnknownType->parse(undef) } qr/^Argument "octets"/;

{
    my $record = Net::FastCGI::Record::UnknownType->new(0xFF);
    like(
        $record->to_string,
        qr/^type: FCGI_UNKNOWN_TYPE, .* unknown_type: 0xFF/
    );
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_unknown_type
        has_content
        to_string
    ];

    my $record = Net::FastCGI::Record::UnknownType->new(0);

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

