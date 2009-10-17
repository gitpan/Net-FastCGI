package Net::FastCGI::Header;

use strict;
use warnings;

use Net::FastCGI::Protocol qw[ build_header
                               parse_header
                               compute_padding_length
                               get_type_name ];
use Net::FastCGI::Util     qw[ :croak :uint ];

sub new {
    ( @_ >= 3 && @_ <= 5 ) || croak(q/Usage: / . __PACKAGE__ . q/->new(type, request_id [, content_length [, padding_length ]])/);
    my ( $class, $type, $request_id, $content_length, $padding_length ) = @_;

    ( is_uint8($type) )
      || croakf( ERRMSG_UINT8, q/type/);

    ( is_uint16($request_id) )
      || croakf( ERRMSG_UINT16, q/request_id/);

    ( @_ < 4 || is_uint16($content_length) )
      || croakf( ERRMSG_UINT16, q/content_length/);

    ( @_ < 5 || is_uint8($padding_length) )
      || croakf( ERRMSG_UINT8, q/padding_length/);

    if ( @_ < 4 ) {
        $content_length = 0;
    }

    if ( @_ < 5 ) {
        $padding_length = ( @_ < 4 ) ? 0 : compute_padding_length($content_length);
    }

    my $self = {
        type           => $type,
        request_id     => $request_id,
        content_length => $content_length,
        padding_length => $padding_length,
    };

    return bless( $self, $class );
}

sub parse {
    @_ == 2 || croak(q/Usage: / . __PACKAGE__ . q/->parse(octets)/);
    return $_[0]->new( parse_header($_[1]) );
}

sub build {
    @_ == 1 || croak(q/Usage: $header->build()/);
    return build_header(
        $_[0]->{type},
        $_[0]->{request_id},
        $_[0]->{content_length},
        $_[0]->{padding_length}
    );
}

sub to_string {
    @_ == 1 || croak(q/Usage: $header->to_string()/);
    return sprintf( q/FCGI_Header type: %s, request_id: %u, content_length: %u, padding_length: %u/,
        get_type_name($_[0]->{type}),
        $_[0]->{request_id},
        $_[0]->{content_length},
        $_[0]->{padding_length}
    );
}

sub get_type {
    @_ == 1 || croak(q/Usage: $header->get_type()/);
    return $_[0]->{type};
}

sub get_request_id {
    @_ == 1 || croak(q/Usage: $header->get_request_id()/);
    return $_[0]->{request_id};
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $header->get_content_length()/);
    return $_[0]->{content_length};
}

sub has_content {
    @_ == 1 || croak(q/Usage: $header->has_content()/);
    return !!$_[0]->{content_length};
}

sub get_padding_length {
    @_ == 1 || croak(q/Usage: $header->get_padding_length()/);
    return $_[0]->{padding_length};
}

sub has_padding {
    @_ == 1 || croak(q/Usage: $header->has_padding()/);
    return !!$_[0]->{padding_length};
}

1;
