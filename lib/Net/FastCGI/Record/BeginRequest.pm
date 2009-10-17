package Net::FastCGI::Record::BeginRequest;

use strict;
use warnings;
use base 'Net::FastCGI::Record';

use Net::FastCGI::Constant qw[ FCGI_BEGIN_REQUEST :role :flag ];
use Net::FastCGI::Protocol qw[ build_begin_request_body
                               parse_begin_request_body
                               get_role_name ];
use Net::FastCGI::Util     qw[ :croak :uint ];

sub new {
    @_ == 4 || croak(q/Usage: / . __PACKAGE__ . q/->new(request_id, role, flags)/);
    my ( $class, $request_id, $role, $flags ) = @_;

    my $self = $class->SUPER::new( FCGI_BEGIN_REQUEST, $request_id );

    ( is_uint16($role) )
      || croakf( ERRMSG_UINT16, q/role/ );

    ( is_uint8($flags) )
      || croakf( ERRMSG_UINT8, q/flags/ );

    $self->{role}  = $role;
    $self->{flags} = $flags;

    return $self;
}

sub parse {
    @_ == 3 || croak(q/Usage: / . __PACKAGE__ . q/->parse(request_id, octets)/);
    return $_[0]->new( $_[1], parse_begin_request_body($_[2]) );
}

sub to_string {
    @_ == 1 || croak(q/Usage: $record->to_string()/);
    my ($self) = @_;
    return $_[0]->SUPER::to_string . sprintf( ', role: %s, flags: 0x%.2X',
        get_role_name($self->get_role), $self->get_flags
    );
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    return build_begin_request_body( $_[0]->get_role, $_[0]->get_flags );
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return 8;
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!1;
}

sub get_role {
    @_ == 1 || croak(q/Usage: $record->get_role()/);
    return $_[0]->{role};
}

sub get_flags {
    @_ == 1 || croak(q/Usage: $record->get_flags()/);
    return $_[0]->{flags};
}

sub is_authorizer {
    @_ == 1 || croak(q/Usage: $record->is_authorizer()/);
    return ( $_[0]->get_role == FCGI_AUTHORIZER );
}

sub is_filter {
    @_ == 1 || croak(q/Usage: $record->is_filter()/);
    return ( $_[0]->get_role == FCGI_FILTER );
}

sub is_responder {
    @_ == 1 || croak(q/Usage: $record->is_responder()/);
    return ( $_[0]->get_role == FCGI_RESPONDER );
}

sub should_keep_connection {
    @_ == 1 || croak(q/Usage: $record->should_keep_connection()/);
    return ( $_[0]->get_flags & FCGI_KEEP_CONN );
}

1;

