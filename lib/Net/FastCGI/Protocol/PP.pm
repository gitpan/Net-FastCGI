package Net::FastCGI::Protocol::PP;

use bytes;
use strict;
use warnings;

use Net::FastCGI::Constant qw[:pack :type :role :protocol_status FCGI_VERSION_1 FCGI_NULL_REQUEST_ID FCGI_HEADER_LEN];
use Net::FastCGI::Util     qw[:common];

BEGIN {
    our $VERSION   = 0.01;
    our @EXPORT_OK = qw[ build_begin_request_body
                         build_begin_request_record
                         build_end_request_body
                         build_end_request_record
                         build_header
                         build_padding
                         build_params
                         build_params_pair
                         build_params_pair_header
                         build_record
                         build_unknown_type_body
                         build_unknown_type_record
                         parse_begin_request_body
                         parse_end_request_body
                         parse_header
                         parse_params
                         parse_params_pair
                         parse_params_pair_header
                         parse_unknown_type_body
                         compute_padding_length
                         compute_params_length
                         compute_params_pair_header_length
                         compute_params_pair_length
                         compute_record_length
                         is_known_type
                         is_management_type
                         is_discrete_type
                         is_stream_type
                         get_role_name
                         get_type_name
                         get_protocol_status_name ];

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    require Exporter;
    *import = \&Exporter::import;
}

# FCGI_Header

sub build_header {
    @_ == 4 || croak(q/Usage: build_header(type, request_id, content_length, padding_length)/);
    my ( $type, $request_id, $content_length, $padding_length ) = @_;

    ( is_uint8($type) )
      || croakf( ERRMSG_UINT8, q/type/ );

    ( is_uint16($request_id) )
      || croakf( ERRMSG_UINT16, q/request_id/ );

    ( is_uint16($content_length) )
      || croakf( ERRMSG_UINT16, q/content_length/ );

    ( is_uint8($padding_length) )
      || croakf( ERRMSG_UINT8, q/padding_length/ );

    return pack( FCGI_Header, FCGI_VERSION_1, $type, $request_id, $content_length, $padding_length );
}

sub parse_header {
    @_ == 1 || croak(q/Usage: parse_header(octets)/);
    my ($octets) = @_;

    ( is_octets_ge( $octets, 8 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 8 );

    my ( $version, $type, $request_id, $content_length, $padding_length )
      = unpack( FCGI_Header, $octets );

    ( $version == FCGI_VERSION_1 )
      || croakf( ERRMSG_VERSION, $version );

    return ( $type, $request_id, $content_length, $padding_length );
}

# FCGI_BeginRequestBody

sub build_begin_request_body {
    @_ == 2 || croak(q/Usage: build_begin_request_body(role, flags)/);
    my ( $role, $flags ) = @_;

    ( is_uint16($role) )
      || croakf( ERRMSG_UINT16, q/role/ );

    ( is_uint8($flags) )
      || croakf( ERRMSG_UINT8, q/flags/ );

    return pack( FCGI_BeginRequestBody, $role, $flags );
}

sub parse_begin_request_body {
    @_ == 1 || croak(q/Usage: parse_begin_request_body(octets)/);
    my ($octets) = @_;

    ( is_octets_ge( $octets, 8 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 8 );

    return unpack( FCGI_BeginRequestBody, $octets );
}

# FCGI_EndRequestBody

sub build_end_request_body {
    @_ == 2 || croak(q/Usage: build_end_request_body(application_status, protocol_status)/);
    my ( $application_status, $protocol_status ) = @_;

    ( is_uint32($application_status) )
      || croakf( ERRMSG_UINT32, q/application_status/ );

    ( is_uint8($protocol_status) )
      || croakf( ERRMSG_UINT8, q/protocol_status/ );

    return pack( FCGI_EndRequestBody, $application_status, $protocol_status );
}

sub parse_end_request_body {
    @_ == 1 || croak(q/Usage: parse_end_request_body(octets)/);
    my ($octets) = @_;

    ( is_octets_ge( $octets, 8 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 8 );

    return unpack( FCGI_EndRequestBody, $octets );
}

# FCGI_UnknownTypeBody

sub build_unknown_type_body {
    @_ == 1 || croak(q/Usage: build_unknown_type_body(type)/);
    my ($type) = @_;

    ( is_uint8($type) )
      || croakf( ERRMSG_UINT8, q/type/ );

    return pack( FCGI_UnknownTypeBody, $type );
}

sub parse_unknown_type_body {
    @_ == 1 || croak(q/Usage: parse_unknown_type_body(octets)/);
    my ($octets) = @_;

    ( is_octets_ge( $octets, 8 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 8 );

    return unpack( FCGI_UnknownTypeBody, $octets );
}

# FCGI_BeginRequestRecord

sub build_begin_request_record {
    @_ == 3 || croak(q/Usage: build_begin_request_record(request_id, role, flags)/);
    my ( $request_id, $role, $flags ) = @_;
    return build_record( FCGI_BEGIN_REQUEST, $request_id,
         build_begin_request_body( $role, $flags ) );
}

# FCGI_EndRequestRecord

sub build_end_request_record {
    @_ == 3 || croak(q/Usage: build_end_request_record(request_id, application_status, protocol_status)/);
    my ( $request_id, $application_status, $protocol_status ) = @_;
    return build_record( FCGI_END_REQUEST, $request_id,
         build_end_request_body( $application_status, $protocol_status ) );
}

# FCGI_UnknownTypeRecord

sub build_unknown_type_record {
    @_ == 1 || croak(q/Usage: build_unknown_type_record(type)/);
    my ($type) = @_;
    return build_record( FCGI_UNKNOWN_TYPE, FCGI_NULL_REQUEST_ID,
        build_unknown_type_body($type) );
}

sub build_record {
    @_ == 2 || @_ == 3 || croak(q/Usage: build_record(type, request_id [, content])/);
    my ( $type, $request_id, $content ) = @_;

    my $content_length = defined($content) ? length($content) : 0;
    my $padding_length = _compute_padding_length($content_length);

    ( is_uint16($content_length) )
      || croakf( ERRMSG_OCTETS_LE, q/content/, 0xFFFF );

    my $octets = build_header( $type, $request_id, $content_length, $padding_length );

    if ($content_length) {
        $octets .= $content;
    }

    if ($padding_length) {
        $octets .= _build_padding($padding_length);
    }

    return $octets;
}

sub _build_padding ($) {
    return "\x00" x $_[0];
}

sub build_padding {
    @_ == 1 || croak(q/Usage: build_padding(padding_length)/);
    my ($padding_length) = @_;

    ( is_uint8($padding_length) )
      || croakf( ERRMSG_UINT8, q/padding_length/ );

    return _build_padding($padding_length);
}

sub _compute_padding_length ($) {
    return ( 8 - ( $_[0] % 8 ) ) % 8;
}

sub compute_padding_length {
    @_ == 1 || croak(q/Usage: compute_padding_length(content_length)/);
    my ($content_length) = @_;

    ( is_uint16($content_length) )
      || croakf( ERRMSG_UINT16, q/content_length/ );

    return _compute_padding_length($content_length);
}

sub compute_record_length {
    @_ == 1 || croak(q/Usage: compute_record_length(content_length)/);
    my ($content_length) = @_;

    ( is_uint16($content_length) )
      || croakf( ERRMSG_UINT16, q/content_length/ );

    return FCGI_HEADER_LEN + $content_length + _compute_padding_length($content_length);
}

sub _compute_params_pair_header_length ($$) {
    return ( $_[0] > 127 ? 4 : 1 ) + ( $_[1] > 127 ? 4 : 1 );
}

sub compute_params_pair_header_length {
    @_ == 2 || croak(q/Usage: compute_params_pair_header_length(name_length, value_length)/);
    my ( $name_length, $value_length ) = @_;

    ( is_uint31($name_length) )
      || croakf( ERRMSG_UINT31, q/name_length/ );

    ( is_uint31($value_length) )
      || croakf( ERRMSG_UINT31, q/value_length/ );

    return _compute_params_pair_header_length($name_length, $value_length);
}

sub compute_params_pair_length {
    @_ == 2 || croak(q/Usage: compute_params_pair_length(name, value)/);
    my ( $name, $value ) = @_;

    my $name_length  = defined($name)  ? length($name)  : 0;
    my $value_length = defined($value) ? length($value) : 0;

    ( is_uint31($name_length) )
      || croakf( ERRMSG_OCTETS_LE, q/name/, 0x7FFFFFFF );

    ( is_uint31($value_length) )
      || croakf( ERRMSG_OCTETS_LE, q/value/, 0x7FFFFFFF );

    return _compute_params_pair_header_length($name_length, $value_length)
        + $name_length + $value_length;
}

sub compute_params_length {
    @_ == 1 || croak(q/Usage: compute_params_length(params)/);
    my ($params) = @_;

    ( is_hvref($params) )
      || croakf( ERRMSG_HVREF, q/params/ );

    my $length = 0;
    while ( my ( $name, $value ) = each( %{ $params } ) ) {
        $length += compute_params_pair_length( $name, $value );
    }

    return $length;
}

sub _build_params_length ($) {
    if ( $_[0] > 127 ) {
        return pack( 'N', $_[0] | ( 1 << 31 ) );
    }
    else {
        return pack( 'C', $_[0] );
    }
}

sub _build_params_pair_header ($$) {
    return _build_params_length($_[0]) 
         . _build_params_length($_[1]);
}

sub build_params_pair_header {
    @_ == 2 || croak(q/Usage: build_params_pair_header(name_length, value_length)/);
    my ( $name_length, $value_length ) = @_;

    ( is_uint31($name_length) )
      || croakf( ERRMSG_UINT31, q/name_length/ );

    ( is_uint31($value_length) )
      || croakf( ERRMSG_UINT31, q/value_length/ );

    return _build_params_pair_header($name_length, $value_length);
}

sub build_params_pair {
    @_ == 2 || croak(q/Usage: build_params_pair(name, value)/);
    my ( $name, $value ) = @_;

    my $name_length  = defined($name)  ? length($name)  : 0;
    my $value_length = defined($value) ? length($value) : 0;

    ( is_uint31($name_length) )
      || croakf( ERRMSG_OCTETS_LE, q/name/, 0x7FFFFFFF );

    ( is_uint31($value_length) )
      || croakf( ERRMSG_OCTETS_LE, q/value/, 0x7FFFFFFF );

    my $octets = _build_params_pair_header($name_length, $value_length);

    if ($name_length) {
        $octets .= $name;
    }

    if ($value_length) {
        $octets .= $value;
    }

    return $octets;
}

sub build_params {
    @_ == 1 || croak(q/Usage: build_params(params)/);
    my ($params) = @_;

    ( is_hvref($params) )
      || croakf( ERRMSG_HVREF, q/params/ );

    my $octets = '';
    while ( my ( $name, $value ) = each( %{ $params } ) ) {
        $octets .= build_params_pair( $name, $value );
    }

    return $octets;
}

sub _parse_params_length (\$$\$) {
    my ( $octets, $length, $offset ) = @_;

    ( $length >= $$offset + 1 )
      || return;

    my $len = unpack( "x${$offset}C", $$octets );

    if ( $len > 127 ) {

        ( $length >= $$offset + 4 )
          || return;

        $len = unpack( "x${$offset}N", $$octets ) & ( 1 << 31 ) - 1;
    }

    $$offset += ( $len > 127 ) ? 4 : 1;

    return $len;
}

sub _parse_params_pair_header (\$$\$) {

    (    defined( my $name_length  = &_parse_params_length ) 
      && defined( my $value_length = &_parse_params_length ) )
      || croak(q/Unexpected end of octets while parsing FCGI_NameValuePair header/);

    return ($name_length, $value_length);
}

sub parse_params_pair_header {
    @_ == 1 || @_ == 2 || croak(q/Usage: parse_params_pair_header(octets [, offset])/);

    ( is_octets_ge( $_[0], 2 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 2 );

    my $length = length($_[0]);
    my $offset = ( @_ == 1 ) ? 0 : do {

        ( is_uint($_[1]) )
          || croakf( ERRMSG_UINT, q/offset/ );

        ( $_[1] <= $length )
          || croakf( ERRMSG_OFFSET, q/offset/ );

        $_[1];
    };

    my $start = $offset;

    return ( _parse_params_pair_header($_[0], $length, $offset), $offset - $start );
}

sub _parse_params_pair (\$$\$) {
    my ( $octets, $length, $offset) = @_;

    my ( $name_length, $value_length ) = &_parse_params_pair_header;

    ( $length >= $$offset + $name_length )
      || croak(q/Unexpected end of octets while parsing FCGI_NameValuePair name/);

    my $name = substr( $$octets, $$offset, $name_length );

    $$offset += $name_length;

    ( $length >= $$offset + $value_length )
      || croak(q/Unexpected end of octets while parsing FCGI_NameValuePair value/);

    my $value = substr( $$octets, $$offset, $value_length );

    $$offset += $value_length;

    return ($name, $value);
}

sub parse_params_pair {
    @_ == 1 || @_ == 2 || croak(q/Usage: parse_params_pair(octets [, offset])/);

    ( is_octets_ge( $_[0], 2 ) )
      || croakf( ERRMSG_OCTETS_GE, q/octets/, 2 );

    my $length = length($_[0]);
    my $offset = ( @_ == 1 ) ? 0 : do {

        ( is_uint($_[1]) )
          || croakf( ERRMSG_UINT, q/offset/ );

        ( $_[1] <= $length )
          || croakf( ERRMSG_OFFSET, q/offset/ );

        $_[1];
    };

    my $start = $offset;

    return ( _parse_params_pair( $_[0], $length, $offset ), $offset - $start );
}

sub parse_params {
    @_ == 1 || croak(q/Usage: parse_params(octets)/);

    my $length = is_octets($_[0]) ? length($_[0]) : 0;
    my $offset = 0;
    my %params = ();

    while ( $length > $offset ) {
        my ( $name, $value ) = _parse_params_pair( $_[0], $length, $offset );
        $params{$name} = $value;
    }

    return \%params;
}

sub is_known_type {
    @_ == 1 || croak(q/Usage: is_known_type(type)/);
    my ($type) = @_;

    if ( !is_uint8($type) || !$type || $type > FCGI_MAXTYPE ) {
        return !!0;
    }

    return !!1;
}

sub is_discrete_type {
    @_ == 1 || croak(q/Usage: is_discrete_type(type)/);
    my ($type) = @_;

    if ( is_uint8($type) ) {

        if (    $type == FCGI_BEGIN_REQUEST
             || $type == FCGI_ABORT_REQUEST
             || $type == FCGI_END_REQUEST
             || $type == FCGI_GET_VALUES
             || $type == FCGI_GET_VALUES_RESULT
             || $type == FCGI_UNKNOWN_TYPE ) {

            return !!1;
        }
    }

    return !!0;
}

sub is_management_type {
    @_ == 1 || croak(q/Usage: is_management_type(type)/);
    my ($type) = @_;

    if ( is_uint8($type) ) {

        if (    $type == FCGI_GET_VALUES
             || $type == FCGI_GET_VALUES_RESULT
             || $type == FCGI_UNKNOWN_TYPE ) {

            return !!1;
        }
    }

    return !!0;
}

sub is_stream_type {
    @_ == 1 || croak(q/Usage: is_stream_type(type)/);
    my ($type) = @_;

    if ( is_uint8($type) ) {

        if (    $type == FCGI_PARAMS
             || $type == FCGI_STDIN
             || $type == FCGI_STDOUT
             || $type == FCGI_STDERR
             || $type == FCGI_DATA ) {

            return !!1;
        }
    }

    return !!0;
}

{
    my @NAME;
       $NAME[FCGI_BEGIN_REQUEST]     = 'FCGI_BEGIN_REQUEST';
       $NAME[FCGI_ABORT_REQUEST]     = 'FCGI_ABORT_REQUEST';
       $NAME[FCGI_END_REQUEST]       = 'FCGI_END_REQUEST';
       $NAME[FCGI_PARAMS]            = 'FCGI_PARAMS';
       $NAME[FCGI_STDIN]             = 'FCGI_STDIN';
       $NAME[FCGI_STDOUT]            = 'FCGI_STDOUT';
       $NAME[FCGI_STDERR]            = 'FCGI_STDERR';
       $NAME[FCGI_DATA]              = 'FCGI_DATA';
       $NAME[FCGI_GET_VALUES]        = 'FCGI_GET_VALUES';
       $NAME[FCGI_GET_VALUES_RESULT] = 'FCGI_GET_VALUES_RESULT';
       $NAME[FCGI_UNKNOWN_TYPE]      = 'FCGI_UNKNOWN_TYPE';

    sub get_type_name {
        @_ == 1 || croak(q/Usage: get_type_name(type)/);
        my ($type) = @_;

        ( is_uint8($type) )
          || croakf( ERRMSG_UINT8, q/type/ );

        return exists($NAME[$type])
          ? $NAME[$type]
          : sprintf( 'Unknown (0x%.2X)', $type );
    }
}

{
    my @NAME;
       $NAME[FCGI_RESPONDER]  = 'FCGI_RESPONDER';
       $NAME[FCGI_AUTHORIZER] = 'FCGI_AUTHORIZER';
       $NAME[FCGI_FILTER]     = 'FCGI_FILTER';

    sub get_role_name {
        @_ == 1 || croak(q/Usage: get_role_name(role)/);
        my ($role) = @_;

        ( is_uint16($role) )
          || croakf( ERRMSG_UINT16, q/role/ );

        return exists($NAME[$role])
          ? $NAME[$role]
          : sprintf( 'Unknown (0x%.4X)', $role );
    }
}

{
    my @NAME;
       $NAME[FCGI_REQUEST_COMPLETE]  = 'FCGI_REQUEST_COMPLETE';
       $NAME[FCGI_CANT_MPX_CONN]     = 'FCGI_CANT_MPX_CONN';
       $NAME[FCGI_OVERLOADED]        = 'FCGI_OVERLOADED';
       $NAME[FCGI_UNKNOWN_ROLE]      = 'FCGI_UNKNOWN_ROLE';

    sub get_protocol_status_name {
        @_ == 1 || croak(q/Usage: get_protocol_status_name(protocol_status)/);
        my ($protocol_status) = @_;

        ( is_uint8($protocol_status) )
          || croakf( ERRMSG_UINT8, q/protocol_status/ );

        return exists($NAME[$protocol_status])
          ? $NAME[$protocol_status]
          : sprintf( 'Unknown (0x%.2X)', $protocol_status );
    }
}

1;

