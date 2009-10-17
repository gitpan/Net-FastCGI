#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 59;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[ :type ] );
    use_ok('Net::FastCGI::Protocol', qw[ is_discrete_type
                                         is_known_type
                                         is_management_type
                                         is_stream_type ] );
}

{
    my @known = (
        FCGI_BEGIN_REQUEST,
        FCGI_ABORT_REQUEST,
        FCGI_END_REQUEST,
        FCGI_PARAMS,
        FCGI_STDIN,
        FCGI_STDOUT,
        FCGI_STDERR,
        FCGI_DATA,
        FCGI_GET_VALUES,
        FCGI_GET_VALUES_RESULT,
        FCGI_UNKNOWN_TYPE,
        FCGI_MAXTYPE,
    );

    foreach my $type ( @known ) {
        is( is_known_type($type), !!1, qq/is_known_type($type) = true/ );
    }
}

{
    my @discrete = (
        FCGI_BEGIN_REQUEST,
        FCGI_ABORT_REQUEST,
        FCGI_END_REQUEST,
        FCGI_GET_VALUES,
        FCGI_GET_VALUES_RESULT,
        FCGI_UNKNOWN_TYPE,
    );

    foreach my $type ( @discrete ) {
        is( is_stream_type($type),   !!0, qq/is_stream_type($type) = false/ );
        is( is_discrete_type($type), !!1, qq/is_discrete_type($type) = true/ );
    }
}

{
    my @management = (
        FCGI_GET_VALUES,
        FCGI_GET_VALUES_RESULT,
        FCGI_UNKNOWN_TYPE,
    );

    foreach my $type ( @management ) {
        is( is_management_type($type), !!1, qq/is_management_type($type) = true/ );
    }
}

{
    my @stream = (
        FCGI_PARAMS,
        FCGI_STDIN,
        FCGI_STDOUT,
        FCGI_STDERR,
        FCGI_DATA,
    );

    foreach my $type ( @stream ) {
        is( is_stream_type($type),   !!1, qq/is_stream_type($type) = true/    );
        is( is_discrete_type($type), !!0, qq/is_discrete_type($type) = false/ );
    }
}

foreach my $type ( undef, -1, 0, 0xFF ) {
    my $label = defined($type) ? $type : 'undef';
    is( is_known_type($type),      !!0, qq/is_known_type($label) = false/ );
    is( is_discrete_type($type),   !!0, qq/is_discrete_type($label) = false/ );
    is( is_management_type($type), !!0, qq/is_management_type($label) = false/ );
    is( is_stream_type($type),     !!0, qq/is_stream_type($label) = false/ );
}

throws_ok { is_known_type()      } qr/^Usage: /;
throws_ok { is_discrete_type()   } qr/^Usage: /;
throws_ok { is_management_type() } qr/^Usage: /;
throws_ok { is_stream_type()     } qr/^Usage: /;

