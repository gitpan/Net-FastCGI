package Net::FastCGI::Record::UnknownType;

use strict;
use warnings;
use base 'Net::FastCGI::Record';

use Net::FastCGI::Constant qw[ FCGI_NULL_REQUEST_ID
                               FCGI_UNKNOWN_TYPE ];
use Net::FastCGI::Protocol qw[ build_unknown_type_body
                               parse_unknown_type_body ];
use Net::FastCGI::Util     qw[ :croak :uint ];

sub new {
    @_ == 2 || croak(q/Usage: / . __PACKAGE__ . q/->new(unknown_type)/);
    my ( $class, $unknown_type ) = @_;

    my $self = $class->SUPER::new( FCGI_UNKNOWN_TYPE, FCGI_NULL_REQUEST_ID );

    ( is_uint8($unknown_type) )
      || croakf( ERRMSG_UINT8, q/unknown_type/ );

    $self->{unknown_type} = $unknown_type;

    return $self;
}

sub parse {
    @_ == 2 || croak(q/Usage: / . __PACKAGE__ . q/->parse(octets)/);
    return $_[0]->new( parse_unknown_type_body($_[1]) );
}

sub to_string {
    @_ == 1 || croak(q/Usage: $record->to_string()/);
    return $_[0]->SUPER::to_string . sprintf(', unknown_type: 0x%.2X',
        $_[0]->get_unknown_type
    );
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    return build_unknown_type_body($_[0]->get_unknown_type);
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return 8;
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!1;
}

sub get_unknown_type {
    @_ == 1 || croak(q/Usage: $record->get_unknown_type()/);
    return $_[0]->{unknown_type};
}

1;

