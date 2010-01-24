package Net::FastCGI::Protocol::PP;
use strict;
use warnings;

use Carp                   qw[croak];
use Net::FastCGI::Constant qw[:all];

BEGIN {
    our $VERSION   = 0.03;
    our @EXPORT_OK = qw[ build_begin_request_body
                         build_begin_request_record
                         build_end_request_body
                         build_end_request_record
                         build_header
                         build_params
                         build_record
                         build_stream
                         build_unknown_type_body
                         build_unknown_type_record
                         parse_begin_request_body
                         parse_end_request_body
                         parse_header
                         parse_params
                         parse_unknown_type_body
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

sub ERRMSG_VERSION   () { q/Unsupported FastCGI version: %u/ }
sub ERRMSG_PARAMS    () { q/Unexpected end of octets while parsing FCGI_NameValuePair/ }
sub ERRMSG_OCTETS_GE () { q/Argument '%s' must be greater than or equal to %u octets in length/ }
sub ERRMSG_OCTETS_LE () { q/Argument '%s' must be less than or equal to %u octets in length/ }

sub throw {
    @_ = ( sprintf($_[0], @_[1..$#_]) ) if @_ > 1;
    goto \&croak;
}

# FCGI_Header

sub build_header {
    @_ == 4 || throw(q/Usage: build_header(type, request_id, content_length, padding_length)/);
    return pack(FCGI_Header, FCGI_VERSION_1, @_);
}

sub parse_header {
    @_ == 1 || throw(q/Usage: parse_header(octets)/);
    (defined $_[0] && length $_[0] >= 8)
      || throw(ERRMSG_OCTETS_GE, q/octets/, 8);
    (unpack('C', $_[0]) == FCGI_VERSION_1)
      || throw(ERRMSG_VERSION, unpack('C', $_[0]));
    return unpack('xCnnCx', $_[0]);
}

# FCGI_BeginRequestBody

sub build_begin_request_body {
    @_ == 2 || throw(q/Usage: build_begin_request_body(role, flags)/);
    return pack(FCGI_BeginRequestBody, @_);
}

sub parse_begin_request_body {
    @_ == 1 || throw(q/Usage: parse_begin_request_body(octets)/);
    (defined $_[0] && length $_[0] >= 8)
      || throw(ERRMSG_OCTETS_GE, q/octets/, 8);
    return unpack(FCGI_BeginRequestBody, $_[0]);
}

# FCGI_EndRequestBody

sub build_end_request_body {
    @_ == 2 || throw(q/Usage: build_end_request_body(application_status, protocol_status)/);
    return pack(FCGI_EndRequestBody, @_);
}

sub parse_end_request_body {
    @_ == 1 || throw(q/Usage: parse_end_request_body(octets)/);
    (defined $_[0] && length $_[0] >= 8)
      || throw(ERRMSG_OCTETS_GE, q/octets/, 8);
    return unpack(FCGI_EndRequestBody, $_[0]);
}

# FCGI_UnknownTypeBody

sub build_unknown_type_body {
    @_ == 1 || throw(q/Usage: build_unknown_type_body(type)/);
    return pack(FCGI_UnknownTypeBody, @_);
}

sub parse_unknown_type_body {
    @_ == 1 || throw(q/Usage: parse_unknown_type_body(octets)/);
    (defined $_[0] && length $_[0] >= 8)
      || throw(ERRMSG_OCTETS_GE, q/octets/, 8);
    return unpack(FCGI_UnknownTypeBody, $_[0]);
}

# FCGI_BeginRequestRecord

sub build_begin_request_record {
    @_ == 3 || throw(q/Usage: build_begin_request_record(request_id, role, flags)/);
    my ($request_id, $role, $flags) = @_;
    return build_record(FCGI_BEGIN_REQUEST, $request_id,
         build_begin_request_body($role, $flags));
}

# FCGI_EndRequestRecord

sub build_end_request_record {
    @_ == 3 || throw(q/Usage: build_end_request_record(request_id, application_status, protocol_status)/);
    my ($request_id, $application_status, $protocol_status) = @_;
    return build_record(FCGI_END_REQUEST, $request_id,
         build_end_request_body($application_status, $protocol_status));
}

# FCGI_UnknownTypeRecord

sub build_unknown_type_record {
    @_ == 1 || throw(q/Usage: build_unknown_type_record(type)/);
    my ($type) = @_;
    return build_record(FCGI_UNKNOWN_TYPE, FCGI_NULL_REQUEST_ID,
        build_unknown_type_body($type));
}

sub build_record {
    @_ == 2 || @_ == 3 || throw(q/Usage: build_record(type, request_id [, content])/);
    my ($type, $request_id) = @_;

    my $content_length = defined $_[2] ? length $_[2] : 0;
    my $padding_length = (8 - ($content_length % 8)) % 8;

    ($content_length <= 0xFFFF)
      || throw(ERRMSG_OCTETS_LE, q/content/, 0xFFFF);

    my $octets = build_header($type, $request_id, $content_length, $padding_length);

    if ($content_length) {
        $octets .= pop;
    }

    if ($padding_length) {
        $octets .= "\x00" x $padding_length;
    }

    return $octets;
}

sub FCGI_CONTENT_LEN () { 8192 - FCGI_HEADER_LEN }

sub build_stream {
    @_ == 3 || @_ == 4 || throw(q/Usage: build_stream(type, request_id, octets [, terminate])/);
    my ($type, $request_id, $octets, $terminate) = @_;

    my $remain = defined $octets ? length $octets : 0;
    my $length;
    my $stream;

    while ($remain) {
        $length = ($remain > FCGI_CONTENT_LEN) ? FCGI_CONTENT_LEN : $remain;
        $stream .= build_record($type, $request_id, substr($octets, 0, $length, ''));
        $remain -= $length;
    }

    if ($terminate) {
        $stream .= build_record($type, $request_id);
    }

    return $stream;
}

sub build_params {
    @_ == 1 || throw(q/Usage: build_params(params)/);
    my ($params) = @_;
    my $res = '';
    while (my ($key, $val) = each(%$params)) {
        for ($key, $val) {
            my $len = defined $_ ? length : 0;
            $res .= $len < 0x80 ? pack('C', $len) : pack('N', $len | 0x80000000);
        }
        $res .= $key;
        $res .= $val if defined $val;
    }
    return $res;
}

sub parse_params {
    @_ == 1 || throw(q/Usage: parse_params(params)/);
    my ($octets) = @_;

    my $params = {};

    (defined $octets && length $octets > 0)
      || return $params;

    my ($klen, $vlen);
    while (length $octets) {
        for ($klen, $vlen) {
            last if 1 > length $octets;
            $_ = unpack('C', substr($octets, 0, 1, ''));
            next if $_ < 0x80;
            last if 3 > length $octets;
            $_ = unpack('N', pack('C', $_ & 0x7F) . substr($octets, 0, 3, ''));
        }
        last if $klen + $vlen > length $octets;
        my $key = substr($octets, 0, $klen, '');
        $params->{$key} = substr($octets, 0, $vlen, '');
    }
    (length $octets == 0)
      || throw(ERRMSG_PARAMS);
    return $params;
}

sub is_known_type {
    @_ == 1 || throw(q/Usage: is_known_type(type)/);
    my ($type) = @_;
    return ($type > 0 && $type <= FCGI_MAXTYPE);
}

sub is_discrete_type {
    @_ == 1 || throw(q/Usage: is_discrete_type(type)/);
    my ($type) = @_;
    return (   $type == FCGI_BEGIN_REQUEST
            || $type == FCGI_ABORT_REQUEST
            || $type == FCGI_END_REQUEST
            || $type == FCGI_GET_VALUES
            || $type == FCGI_GET_VALUES_RESULT
            || $type == FCGI_UNKNOWN_TYPE );
}

sub is_management_type {
    @_ == 1 || throw(q/Usage: is_management_type(type)/);
    my ($type) = @_;
    return (   $type == FCGI_GET_VALUES
            || $type == FCGI_GET_VALUES_RESULT
            || $type == FCGI_UNKNOWN_TYPE );
}

sub is_stream_type {
    @_ == 1 || throw(q/Usage: is_stream_type(type)/);
    my ($type) = @_;
    return (   $type == FCGI_PARAMS
            || $type == FCGI_STDIN
            || $type == FCGI_STDOUT
            || $type == FCGI_STDERR
            || $type == FCGI_DATA );
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
        @_ == 1 || throw(q/Usage: get_type_name(type)/);
        my ($type) = @_;
        return exists($NAME[$type])
          ? $NAME[$type]
          : sprintf('UNKNOWN (0x%.2X)', $type);
    }
}

{
    my @NAME;
       $NAME[FCGI_RESPONDER]  = 'FCGI_RESPONDER';
       $NAME[FCGI_AUTHORIZER] = 'FCGI_AUTHORIZER';
       $NAME[FCGI_FILTER]     = 'FCGI_FILTER';

    sub get_role_name {
        @_ == 1 || throw(q/Usage: get_role_name(role)/);
        my ($role) = @_;
        return exists($NAME[$role])
          ? $NAME[$role]
          : sprintf('UNKNOWN (0x%.4X)', $role);
    }
}

{
    my @NAME;
       $NAME[FCGI_REQUEST_COMPLETE]  = 'FCGI_REQUEST_COMPLETE';
       $NAME[FCGI_CANT_MPX_CONN]     = 'FCGI_CANT_MPX_CONN';
       $NAME[FCGI_OVERLOADED]        = 'FCGI_OVERLOADED';
       $NAME[FCGI_UNKNOWN_ROLE]      = 'FCGI_UNKNOWN_ROLE';

    sub get_protocol_status_name {
        @_ == 1 || throw(q/Usage: get_protocol_status_name(protocol_status)/);
        my ($protocol_status) = @_;
        return exists($NAME[$protocol_status])
          ? $NAME[$protocol_status]
          : sprintf('UNKNOWN (0x%.2X)', $protocol_status);
    }
}

1;

