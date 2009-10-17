package Net::FastCGI::RecordFactory;

use strict;
use warnings;

use Net::FastCGI::Constant             qw[ :type :value ];
use Net::FastCGI::Protocol             qw[ is_stream_type
                                           is_management_type ];
use Net::FastCGI::Record               qw[];
use Net::FastCGI::Record::BeginRequest qw[];
use Net::FastCGI::Record::EndRequest   qw[];
use Net::FastCGI::Record::Stream       qw[];
use Net::FastCGI::Record::Values       qw[];
use Net::FastCGI::Record::UnknownType  qw[];
use Net::FastCGI::Util                 qw[ :carp ];

my $SINGLETON = bless( {}, __PACKAGE__ );

sub new {
    @_ == 1 || croak(q/Usage: / . __PACKAGE__ . q/->new()/);
    return $SINGLETON;
}

sub create_abort_request {
    @_ == 2 || croak(q/Usage: $factory->create_abort_request(request_id)/);
    return Net::FastCGI::Record->new( FCGI_ABORT_REQUEST, $_[1] );
}

sub create_begin_request {
    @_ == 4 || croak(q/Usage: $factory->create_begin_request(request_id, role, flags)/);
    return Net::FastCGI::Record::BeginRequest->new( @_[ 1 .. 3 ] );
}

sub create_end_request {
    @_ == 4 || croak(q/Usage: $factory->create_end_request(request_id, application_status, protocol_statuss)/);
    return Net::FastCGI::Record::EndRequest->new( @_[ 1 .. 3 ] );
}

sub create_unknown_type {
    @_ == 2 || croak(q/Usage: $factory->create_unknown_type(type)/);
    return Net::FastCGI::Record::UnknownType->new($_[1]);
}

sub create_stream {
    @_ == 3 || @_ == 4 || croak(q/Usage: $factory->create_stream(type, request_id [, content])/);
    return Net::FastCGI::Record::Stream->new( @_[ 1 .. $#_ ] );
}

sub create_stdin {
    @_ == 2 || @_ == 3 || croak(q/Usage: $factory->create_stdin(request_id [, content])/);
    return shift->create_stream( FCGI_STDIN, @_ );
}

sub create_stdout {
    @_ == 2 || @_ == 3 || croak(q/Usage: $factory->create_stdout(request_id [, content])/);
    return shift->create_stream( FCGI_STDOUT, @_ );
}

sub create_stderr {
    @_ == 2 || @_ == 3 || croak(q/Usage: $factory->create_stderr(request_id [, content])/);
    return shift->create_stream( FCGI_STDERR, @_ );
}

sub create_params {
    @_ == 2 || @_ == 3 || croak(q/Usage: $factory->create_params(request_id [, content])/);
    return shift->create_stream( FCGI_PARAMS, @_ );
}

sub create_data {
    @_ == 2 || @_ == 3 || croak(q/Usage: $factory->create_data(request_id [, content])/);
    return shift->create_stream( FCGI_DATA, @_ );
}

sub create_values {
    @_ == 3 || croak(q/Usage: $factory->create_values(type, values)/);
    return Net::FastCGI::Record::Values->new( @_[ 1 .. 2 ] );
}

my %DEFAULT_VALUES = (
    &FCGI_MAX_CONNS  => '',
    &FCGI_MAX_REQS   => '',
    &FCGI_MPXS_CONNS => '',
);

sub create_get_values {
    @_ == 1 || @_ == 2 || croak(q/Usage: $factory->create_get_values([values])/);
    return $_[0]->create_values( FCGI_GET_VALUES, ( @_ == 2 ) ? $_[1] : { %DEFAULT_VALUES } );
}

sub create_get_values_result {
    @_ == 2 || croak(q/Usage: $factory->create_get_values_result(values)/);
    return $_[0]->create_values( FCGI_GET_VALUES_RESULT, $_[1] );
}

sub parse {
    @_ == 3 || @_ == 4 || croak(q/Usage: $factory->parse(type, request_id [, content])/);
    my ( $self, $type, $request_id, $content ) = @_;

    if ( $type == FCGI_ABORT_REQUEST ) {
        return Net::FastCGI::Record->new( FCGI_ABORT_REQUEST, $request_id );
    }

    if ( $type == FCGI_BEGIN_REQUEST ) {
        return Net::FastCGI::Record::BeginRequest->parse( $request_id, $content );
    }

    if ( $type == FCGI_END_REQUEST ) {
        return Net::FastCGI::Record::EndRequest->parse( $request_id, $content );
    }

    if ( is_stream_type($type) ) {
        return $self->create_stream( $type, $request_id, $content );
    }

    if (    $type == FCGI_GET_VALUES
         || $type == FCGI_GET_VALUES_RESULT ) {
        return Net::FastCGI::Record::Values->parse( $type, $content );
    }

    if ( $type == FCGI_UNKNOWN_TYPE ) {
        return Net::FastCGI::Record::UnknownType->parse($content);
    }

    return Net::FastCGI::Record::UnknownType->new($type);
}

1;

