#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 140;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[:type]);
    use_ok('Net::FastCGI::RecordFactory');
}

{
    my @methods = qw[
        create_abort_request
        create_begin_request
        create_end_request
        create_stream
        create_params
        create_stderr
        create_stdin
        create_stdout
        create_data
        create_unknown_type
        create_values
        create_get_values
        create_get_values_result
        new
        parse
    ];

    can_ok( 'Net::FastCGI::RecordFactory', @methods );
}

{
    my $factory = Net::FastCGI::RecordFactory->new;
    isa_ok( $factory, 'Net::FastCGI::RecordFactory' );
}

{
    my $A = Net::FastCGI::RecordFactory->new;
    my $B = Net::FastCGI::RecordFactory->new;
    cmp_ok( $A, '==', $B, 'Net::FastCGI::RecordFactory->new returns a singleton' );
}

{
    my @tests = (
        # method                       class                                type                    @arguments
        [ 'create_abort_request',     'Net::FastCGI::Record',               FCGI_ABORT_REQUEST,     0         ],
        [ 'create_begin_request',     'Net::FastCGI::Record::BeginRequest', FCGI_BEGIN_REQUEST,     0, 0, 0   ],
        [ 'create_data',              'Net::FastCGI::Record::Stream',       FCGI_DATA,              0         ],
        [ 'create_data',              'Net::FastCGI::Record::Stream',       FCGI_DATA,              0, "\x41" ],
        [ 'create_end_request',       'Net::FastCGI::Record::EndRequest',   FCGI_END_REQUEST,       0, 0, 0   ],
        [ 'create_get_values',        'Net::FastCGI::Record::Values',       FCGI_GET_VALUES,                  ],
        [ 'create_get_values',        'Net::FastCGI::Record::Values',       FCGI_GET_VALUES,        {}        ],
        [ 'create_get_values_result', 'Net::FastCGI::Record::Values',       FCGI_GET_VALUES_RESULT, {}        ],
        [ 'create_params',            'Net::FastCGI::Record::Stream',       FCGI_PARAMS,            0         ],
        [ 'create_params',            'Net::FastCGI::Record::Stream',       FCGI_PARAMS,            0, "\x41" ],
        [ 'create_stderr',            'Net::FastCGI::Record::Stream',       FCGI_STDERR,            0         ],
        [ 'create_stderr',            'Net::FastCGI::Record::Stream',       FCGI_STDERR,            0, "\x41" ],
        [ 'create_stdin',             'Net::FastCGI::Record::Stream',       FCGI_STDIN,             0         ],
        [ 'create_stdin',             'Net::FastCGI::Record::Stream',       FCGI_STDIN,             0, "\x41" ],
        [ 'create_stdout',            'Net::FastCGI::Record::Stream',       FCGI_STDOUT,            0         ],
        [ 'create_stdout',            'Net::FastCGI::Record::Stream',       FCGI_STDOUT,            0, "\x41" ],
        [ 'create_unknown_type',      'Net::FastCGI::Record::UnknownType',  FCGI_UNKNOWN_TYPE,      0         ],
    );

    my $factory = Net::FastCGI::RecordFactory->new;

    foreach my $test ( @tests ) {
        my ( $method, $class, $type, @arguments ) = @$test;

        my $record;
        lives_ok { $record = $factory->$method(@arguments) } qq/\$factory->$method(@arguments)/;
        isa_ok( $record, $class );
        is( $record->get_type, $type, q/get_type = $type/);
    }
}

{
    my @tests = (
        #  class                                type                    request_id  octets
        [ 'Net::FastCGI::Record',               FCGI_ABORT_REQUEST,              1,                                    ],
        [ 'Net::FastCGI::Record::BeginRequest', FCGI_BEGIN_REQUEST,              1, "\xFF\xFF\xFF\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_DATA,                       1, "\x00\x00\x00\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_DATA,                       1,                                    ],
        [ 'Net::FastCGI::Record::EndRequest',   FCGI_END_REQUEST,                1, "\xFF\xFF\xFF\xFF\xFF\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Values',       FCGI_GET_VALUES,                 0, "\x01\x01\x31\x31"                 ],
        [ 'Net::FastCGI::Record::Values',       FCGI_GET_VALUES,                 0,                                    ],
        [ 'Net::FastCGI::Record::Values',       FCGI_GET_VALUES_RESULT,          0,                                    ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_PARAMS,                     1, "\x00\x00\x00\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_PARAMS,                     1,                                    ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDERR,                     1, "\x00\x00\x00\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDERR,                     1,                                    ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDIN,                      1, "\x00\x00\x00\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDIN,                      1,                                    ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDOUT,                     1, "\x00\x00\x00\x00\x00\x00\x00\x00" ],
        [ 'Net::FastCGI::Record::Stream',       FCGI_STDOUT,                     1,                                    ],
        [ 'Net::FastCGI::Record::UnknownType',  FCGI_UNKNOWN_TYPE,               0, "\xFF\x00\x00\x00\x00\x00\x00\x00" ],
    );

    my $factory = Net::FastCGI::RecordFactory->new;

    foreach my $test ( @tests ) {
        my ( $class, $type, $request_id, $octets ) = @$test;

        my $record;
        lives_ok { $record = $factory->parse($type, $request_id, $octets) } qq/\$factory->parse($type, $request_id, ...)/;
        isa_ok( $record, $class );
        is( $record->get_type, $type, qq/get_type = $type/ );
        is( $record->get_request_id, $request_id, qq/get_request_id = $request_id/ );
    }
}

{
    my $factory = Net::FastCGI::RecordFactory->new;
    my $record  = $factory->parse( 100, 1 );
    isa_ok( $record, 'Net::FastCGI::Record::UnknownType' );
}

throws_ok { Net::FastCGI::RecordFactory->new(undef) } qr/^Usage: /;
throws_ok { Net::FastCGI::RecordFactory->parse      } qr/^Usage: /;

{
    my @methods = qw[
        create_abort_request
        create_begin_request
        create_data
        create_end_request
        create_get_values
        create_get_values_result
        create_params
        create_stderr
        create_stdin
        create_stdout
        create_stream
        create_unknown_type
        create_values
    ];

    my $factory = Net::FastCGI::RecordFactory->new;

    foreach my $method ( @methods ) {
        throws_ok { $factory->can($method)->() } qr/^Usage: /;
    }
}
