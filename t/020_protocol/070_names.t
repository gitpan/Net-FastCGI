#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 31;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[ :type :role :protocol_status ] );
    use_ok('Net::FastCGI::Protocol', qw[ get_type_name
                                         get_role_name
                                         get_protocol_status_name ] );
}

{
    my @tests = (
        [ FCGI_BEGIN_REQUEST,     'FCGI_BEGIN_REQUEST'     ],
        [ FCGI_ABORT_REQUEST,     'FCGI_ABORT_REQUEST'     ],
        [ FCGI_END_REQUEST,       'FCGI_END_REQUEST'       ],
        [ FCGI_PARAMS,            'FCGI_PARAMS'            ],
        [ FCGI_STDIN,             'FCGI_STDIN'             ],
        [ FCGI_STDOUT,            'FCGI_STDOUT'            ],
        [ FCGI_STDERR,            'FCGI_STDERR'            ],
        [ FCGI_DATA,              'FCGI_DATA'              ],
        [ FCGI_GET_VALUES,        'FCGI_GET_VALUES'        ],
        [ FCGI_GET_VALUES_RESULT, 'FCGI_GET_VALUES_RESULT' ],
        [ FCGI_UNKNOWN_TYPE,      'FCGI_UNKNOWN_TYPE'      ],
    );

    foreach my $test ( @tests ) {
        my ( $type, $name ) = @$test;
        is( get_type_name($type), $name, qq/get_type_name($type) = $name/ );
    }

    foreach my $type ( 0, 0xFF ) {
        like( get_type_name($type), qr/^Unknown \(0x..\)/ );
    }
}

{
    my @tests = (
        [ FCGI_RESPONDER,  'FCGI_RESPONDER'  ],
        [ FCGI_AUTHORIZER, 'FCGI_AUTHORIZER' ],
        [ FCGI_FILTER,     'FCGI_FILTER'     ],
    );

    foreach my $test ( @tests ) {
        my ( $role, $name ) = @$test;
        is( get_role_name($role), $name, qq/get_role_name($role) = $name/ );
    }

    foreach my $role ( 0, 0xFF ) {
        like( get_role_name($role), qr/^Unknown \(0x00..\)/ );
    }
}

{
    my @tests = (
        [ FCGI_REQUEST_COMPLETE, 'FCGI_REQUEST_COMPLETE' ],
        [ FCGI_CANT_MPX_CONN,    'FCGI_CANT_MPX_CONN'    ],
        [ FCGI_OVERLOADED,       'FCGI_OVERLOADED'       ],
        [ FCGI_UNKNOWN_ROLE,     'FCGI_UNKNOWN_ROLE'     ],
    );

    foreach my $test ( @tests ) {
        my ( $status, $name ) = @$test;
        is( get_protocol_status_name($status), $name, qq/get_protocol_status_name($status) = $name/ );
    }

    like( get_protocol_status_name(0xFF), qr/^Unknown \(0xFF\)/ );
}

throws_ok { get_type_name()              } qr/^Usage: /;
throws_ok { get_type_name(-1)            } qr/^Argument "type" is not an unsigned/;
throws_ok { get_role_name()              } qr/^Usage: /;
throws_ok { get_role_name(-1)            } qr/^Argument "role" is not an unsigned/;
throws_ok { get_protocol_status_name()   } qr/^Usage: /;
throws_ok { get_protocol_status_name(-1) } qr/^Argument "protocol_status" is not an unsigned/;
