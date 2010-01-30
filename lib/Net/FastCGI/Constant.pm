package Net::FastCGI::Constant;

use strict;
use warnings;

BEGIN {
    our $VERSION        = 0.04;
    my @common          = qw[ FCGI_MAX_LENGTH
                              FCGI_HEADER_LEN
                              FCGI_VERSION_1
                              FCGI_NULL_REQUEST_ID ];

    my @type            = qw[ FCGI_BEGIN_REQUEST
                              FCGI_ABORT_REQUEST
                              FCGI_END_REQUEST
                              FCGI_PARAMS
                              FCGI_STDIN
                              FCGI_STDOUT
                              FCGI_STDERR
                              FCGI_DATA
                              FCGI_GET_VALUES
                              FCGI_GET_VALUES_RESULT
                              FCGI_UNKNOWN_TYPE
                              FCGI_MAXTYPE ];

    my @role            = qw[ FCGI_RESPONDER
                              FCGI_AUTHORIZER
                              FCGI_FILTER ];

    my @flag            = qw[ FCGI_KEEP_CONN ];

    my @protocol_status = qw[ FCGI_REQUEST_COMPLETE
                              FCGI_CANT_MPX_CONN
                              FCGI_OVERLOADED
                              FCGI_UNKNOWN_ROLE ];

    my @value           = qw[ FCGI_MAX_CONNS
                              FCGI_MAX_REQS
                              FCGI_MPXS_CONNS ];

    my @pack            = qw[ FCGI_Header
                              FCGI_BeginRequestBody
                              FCGI_EndRequestBody
                              FCGI_UnknownTypeBody ];

    our @EXPORT_OK      = (  @common,
                             @type,
                             @role,
                             @flag,
                             @protocol_status,
                             @value,
                             @pack );

    our %EXPORT_TAGS =    (  all             => \@EXPORT_OK,
                             common          => \@common,
                             type            => \@type,
                             role            => \@role,
                             flag            => \@flag,
                             protocol_status => \@protocol_status,
                             value           => \@value,
                             pack            => \@pack );

    require Exporter;
    *import = \&Exporter::import;
}

# common
sub FCGI_MAX_LENGTH          () { 0xFFFF }
sub FCGI_HEADER_LEN          () {      8 }
sub FCGI_VERSION_1           () {      1 }
sub FCGI_NULL_REQUEST_ID     () {      0 }

# type
sub FCGI_BEGIN_REQUEST       () {      1 }
sub FCGI_ABORT_REQUEST       () {      2 }
sub FCGI_END_REQUEST         () {      3 }
sub FCGI_PARAMS              () {      4 }
sub FCGI_STDIN               () {      5 }
sub FCGI_STDOUT              () {      6 }
sub FCGI_STDERR              () {      7 }
sub FCGI_DATA                () {      8 }
sub FCGI_GET_VALUES          () {      9 }
sub FCGI_GET_VALUES_RESULT   () {     10 }
sub FCGI_UNKNOWN_TYPE        () {     11 }
sub FCGI_MAXTYPE             () { FCGI_UNKNOWN_TYPE }

# role
sub FCGI_RESPONDER           () {      1 }
sub FCGI_AUTHORIZER          () {      2 }
sub FCGI_FILTER              () {      3 }

# flags
sub FCGI_KEEP_CONN           () {      1 }

# protocol status
sub FCGI_REQUEST_COMPLETE    () {      0 }
sub FCGI_CANT_MPX_CONN       () {      1 }
sub FCGI_OVERLOADED          () {      2 }
sub FCGI_UNKNOWN_ROLE        () {      3 }

# value
sub FCGI_MAX_CONNS           () { 'FCGI_MAX_CONNS'  }
sub FCGI_MAX_REQS            () { 'FCGI_MAX_REQS'   }
sub FCGI_MPXS_CONNS          () { 'FCGI_MPXS_CONNS' }

# pack
sub FCGI_Header              () { 'CCnnCx' }
sub FCGI_BeginRequestBody    () { 'nCx5'   }
sub FCGI_EndRequestBody      () { 'NCx3'   }
sub FCGI_UnknownTypeBody     () { 'Cx7'    }

1;
