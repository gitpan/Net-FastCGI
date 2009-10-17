package Net::FastCGI::Record;

use strict;
use warnings;

use Net::FastCGI::Constant qw[ FCGI_NULL_REQUEST_ID ];
use Net::FastCGI::Protocol qw[ build_record
                               is_discrete_type
                               is_stream_type
                               get_type_name ];
use Net::FastCGI::Util     qw[ :croak :uint ];

sub new {
    @_ == 3 || croak(q/Usage: / . __PACKAGE__ . q/->new(type, request_id)/);
    my ( $class, $type, $request_id ) = @_;

    ( is_uint8($type) )
      || croakf( ERRMSG_UINT8, q/type/);

    ( is_uint16($request_id) )
      || croakf( ERRMSG_UINT16, q/request_id/);

    my $self = {
        type       => $type,
        request_id => $request_id,
    };

    return bless( $self, $class );
}

sub build {
    @_ == 1 || croak(q/Usage: $record->build()/);
    my ($self) = @_;
    return build_record(
        $self->get_type, $self->get_request_id, $self->get_content
    );
}

sub to_string {
    @_ == 1 || croak(q/Usage: $record->to_string()/);
    my ($self) = @_;
    return sprintf('type: %s, request_id: %u, content_length: %u',
        get_type_name($self->get_type),
        $self->get_request_id,
        $self->get_content_length
    );
}

sub get_type {
    @_ == 1 || croak(q/Usage: $record->get_type()/);
    return $_[0]->{type};
}

sub get_request_id {
    @_ == 1 || croak(q/Usage: $record->get_request_id()/);
    return $_[0]->{request_id};
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    return undef;
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return 0;
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!0;
}

sub is_management {
    @_ == 1 || croak(q/Usage: $record->is_management()/);
    return $_[0]->get_request_id == FCGI_NULL_REQUEST_ID;
}

sub is_discrete {
    @_ == 1 || croak(q/Usage: $record->is_discrete()/);
    return is_discrete_type($_[0]->get_type);
}

sub is_stream {
    @_ == 1 || croak(q/Usage: $record->is_stream()/);
    return is_stream_type($_[0]->get_type);
}

1;

