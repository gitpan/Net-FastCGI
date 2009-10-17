#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 85;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[:type :role :flag]);
    use_ok('Net::FastCGI::Record::BeginRequest');
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_flags
        get_request_id
        get_role
        get_type
        has_content
        is_authorizer
        is_discrete
        is_filter
        is_management
        is_responder
        is_stream
        new
        parse
        should_keep_connection
        to_string
    ];

    can_ok( 'Net::FastCGI::Record::BeginRequest', @methods );
}

{
    my $record = Net::FastCGI::Record::BeginRequest->new( 0, 0, 0 );
    isa_ok( $record, 'Net::FastCGI::Record' );
    isa_ok( $record, 'Net::FastCGI::Record::BeginRequest' );
}

{
    my @tests = (
        # [         header octets         ][        content octets         ]   request_id    role  flags
        [ "\x01\x01\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",           0,      0,     0 ],
        [ "\x01\x01\xFF\xFF\x00\x08\x00\x00\xFF\xFF\xFF\x00\x00\x00\x00\x00",      0xFFFF, 0xFFFF,  0xFF ],
    );

    my $record_test = sub ($$) {
        my ( $record, $test ) = @_;

        is( $record->get_type,          FCGI_BEGIN_REQUEST, qq/get_type = FCGI_BEGIN_REQUEST/ );
        is( $record->get_request_id,            $test->[1], qq/get_request_id = $test->[1]/   );
        is( $record->get_content_length,                 8, qq/get_content_length = 8/        );
        is( $record->has_content,                      !!1, qq/has_content = true/            );
        is( $record->is_stream,                        !!0, qq/is_stream = false/             );
        is( $record->is_discrete,                      !!1, qq/is_discrete = true/            );
        is( $record->get_role,                  $test->[2], qq/get_role = $test->[2]/         );
        is( $record->get_flags,                 $test->[3], qq/get_flags = $test->[3]/        );

        my $content = substr( $test->[0], 8, 8 );

        is_binary( $record->get_content,   $content, qq/get_content/ );
        is_binary( $record->build,       $test->[0], qq/build/       );
    };

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::BeginRequest->new( @$test[1..3] );
        $record_test->( $record, $test );
    }

    foreach my $test ( @tests ) {
        my $content = substr( $test->[0], 8, 8 );
        my $record  = Net::FastCGI::Record::BeginRequest->parse( $test->[1], $content );
        $record_test->( $record, $test );
    }
}

{
    my $record = Net::FastCGI::Record::BeginRequest->new( 1, FCGI_RESPONDER, 0 );
    like(
        $record->to_string,
        qr/^type: FCGI_BEGIN_REQUEST, .* role: FCGI_RESPONDER, flags: 0x00/
    );
}

{
    my @role = (
        0,
        FCGI_RESPONDER,
        FCGI_AUTHORIZER,
        FCGI_FILTER,
    );

    foreach my $role ( @role ) {
        my $record = Net::FastCGI::Record::BeginRequest->new( 0, $role, 0 );

        is( $record->get_role, $role, qq/get_role = $role/ );

        my $is_authorizer = ( $role == FCGI_AUTHORIZER ) ? 'true' : 'false';
        my $is_filter     = ( $role == FCGI_FILTER     ) ? 'true' : 'false';
        my $is_responder  = ( $role == FCGI_RESPONDER  ) ? 'true' : 'false';

        is( $record->is_authorizer, $is_authorizer eq 'true', qq/is_authorizer = $is_authorizer/ );
        is( $record->is_filter,     $is_filter     eq 'true',     qq/is_filter = $is_filter/     );
        is( $record->is_responder,  $is_responder  eq 'true',  qq/is_responder = $is_responder/  );
    }
}

{
    my @flag = (
        0,
        FCGI_KEEP_CONN,
        FCGI_KEEP_CONN | 10,
    );

    foreach my $flags ( @flag ) {
        my $record = Net::FastCGI::Record::BeginRequest->new( 0, 0, $flags );

        is( $record->get_flags, $flags, qq/get_flags = $flags/ );

        my $keep = ( $flags & FCGI_KEEP_CONN );

        is( $record->should_keep_connection, $keep, q/should_keep_connection = / . ( $keep ? 'true' : 'false' ) );
    }
}

throws_ok { Net::FastCGI::Record::BeginRequest->new               } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::BeginRequest->new( -1,  0,  0 ) } qr/^Argument "request_id"/;
throws_ok { Net::FastCGI::Record::BeginRequest->new(  0, -1,  0 ) } qr/^Argument "role"/;
throws_ok { Net::FastCGI::Record::BeginRequest->new(  0,  0, -1 ) } qr/^Argument "flags"/;
throws_ok { Net::FastCGI::Record::BeginRequest->parse             } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::BeginRequest->parse( 0, undef ) } qr/^Argument "octets"/;

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_flags
        get_role
        has_content
        is_authorizer
        is_filter
        is_responder
        should_keep_connection
        to_string
    ];

    my $record = Net::FastCGI::Record::BeginRequest->new( 0, 0, 0 );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

