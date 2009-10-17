package Net::FastCGI::Record::EndRequest;

use strict;
use warnings;
use base 'Net::FastCGI::Record';

use Net::FastCGI::Constant qw[ FCGI_END_REQUEST ];
use Net::FastCGI::Protocol qw[ build_end_request_body
                               parse_end_request_body
                               get_protocol_status_name ];
use Net::FastCGI::Util     qw[ :croak :uint ];

sub new {
    @_ == 4 || croak(q/Usage: / . __PACKAGE__ . q/->new(request_id, application_status, protocol_status)/);
    my ( $class, $request_id, $application_status, $protocol_status ) = @_;

    my $self = $class->SUPER::new( FCGI_END_REQUEST, $request_id );

    ( is_uint32($application_status) )
      || croakf( ERRMSG_UINT32, q/application_status/ );

    ( is_uint8($protocol_status) )
      || croakf( ERRMSG_UINT8, q/protocol_status/ );

    $self->{application_status} = $application_status;
    $self->{protocol_status}    = $protocol_status;

    return $self;
}

sub parse {
    @_ == 3 || croak(q/Usage: / . __PACKAGE__ . q/->parse(request_id, octets)/);
    return $_[0]->new( $_[1], parse_end_request_body($_[2]) );
}

sub to_string {
    @_ == 1 || croak(q/Usage: $record->to_string()/);
    my ($self) = @_;
    return $_[0]->SUPER::to_string . sprintf(', application_status: 0x%.4X, protocol_status: %s',
        $self->get_application_status, get_protocol_status_name($self->get_protocol_status)
    );
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    my ($self) = @_;
    return build_end_request_body(
        $self->get_application_status, $self->get_protocol_status
    );
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return 8;
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!1;
}

sub get_application_status {
    @_ == 1 || croak(q/Usage: $record->get_application_status()/);
    return $_[0]->{application_status};
}

sub get_protocol_status {
    @_ == 1 || croak(q/Usage: $record->get_protocol_status()/);
    return $_[0]->{protocol_status};
}

1;
