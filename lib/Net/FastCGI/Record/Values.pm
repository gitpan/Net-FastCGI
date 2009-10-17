package Net::FastCGI::Record::Values;

use strict;
use warnings;
use base 'Net::FastCGI::Record';

use Net::FastCGI::Constant qw[ FCGI_NULL_REQUEST_ID ];
use Net::FastCGI::Protocol qw[ build_params
                               parse_params
                               compute_params_length ];
use Net::FastCGI::Util     qw[ :common ];

sub new {
    @_ == 3 || croak(q/Usage: / . __PACKAGE__ . q/->new(type, values)/);
    my ( $class, $type, $values ) = @_;

    my $self = $class->SUPER::new( $type, FCGI_NULL_REQUEST_ID );

    ( is_hvref($values) )
      || croakf( ERRMSG_HVREF, q/values/ );

    $self->{content_length} = compute_params_length($values);

    ( is_uint16( $self->{content_length} ) )
      || croakf( ERRMSG_OCTETS_LE, q/values/, 0xFFFF );

    $self->{values} = { %{ $values } };

    return $self;
}

sub parse {
    @_ == 3 || croak(q/Usage: / . __PACKAGE__ . q/->parse(type, octets)/);
    return $_[0]->new( $_[1], parse_params($_[2]) );
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    return build_params( $_[0]->{values} );
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return $_[0]->{content_length};
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!$_[0]->{content_length};
}

sub get_values {
    @_ == 1 || croak(q/Usage: $record->get_values()/);
    return { %{ $_[0]->{values} } };
}

1;
