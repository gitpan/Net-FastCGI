package Net::FastCGI::Record::Stream;

use bytes;
use strict;
use warnings;
use base 'Net::FastCGI::Record';

use Net::FastCGI::Util qw[ :common ];

sub new {
    @_ == 3 || @_ == 4 || croak(q/Usage: / . __PACKAGE__ . q/->new(type, request_id, [, content])/);
    my ( $class, $type, $request_id, $content ) = @_;

    my $self = $class->SUPER::new( $type, $request_id );

    if ( defined($content) ) {

        ( is_octets_le( $content, 0xFFFF ) )
          || croakf( ERRMSG_OCTETS_LE, q/content/, 0xFFFF );

        $self->{content}        = $content;
        $self->{content_length} = length($content);
    }
    else {
        $self->{content_length} = 0;
    }

    return $self;
}

sub get_content {
    @_ == 1 || croak(q/Usage: $record->get_content()/);
    return $_[0]->{content};
}

sub get_content_length {
    @_ == 1 || croak(q/Usage: $record->get_content_length()/);
    return $_[0]->{content_length};
}

sub has_content {
    @_ == 1 || croak(q/Usage: $record->has_content()/);
    return !!$_[0]->{content_length};
}

1;
