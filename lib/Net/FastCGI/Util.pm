package Net::FastCGI::Util;

use strict;
use warnings;

use Carp         qw[carp croak];
use Net::FastCGI qw[];

BEGIN {
    my @carp         = qw[ carp
                           carpf
                           croak
                           croakf ];

    my @errmsg       = qw[ ERRMSG_CVREF
                           ERRMSG_HVREF
                           ERRMSG_INSTANCE_OF
                           ERRMSG_OCTETS_GE
                           ERRMSG_OCTETS_LE
                           ERRMSG_OFFSET
                           ERRMSG_UINT
                           ERRMSG_UINT8
                           ERRMSG_UINT16
                           ERRMSG_UINT31
                           ERRMSG_UINT32
                           ERRMSG_VERSION ];

    my @predicate    = qw[ is_cvref
                           is_hvref
                           is_handle
                           is_instance_of
                           is_object
                           is_octets
                           is_octets_ge
                           is_octets_le
                           is_uint
                           is_uint8
                           is_uint16
                           is_uint31
                           is_uint32 ];

    our @EXPORT_OK   = (   @carp,
                           @errmsg,
                           @predicate );

    our %EXPORT_TAGS = (   all       => \@EXPORT_OK,
                           carp      => \@carp,
                           common    => [ @carp, @predicate, @errmsg ],
                           croak     => [ grep { /croak/ } @carp ],
                           errmsg    => \@errmsg,
                           predicate => \@predicate,
                           uint      => [ grep { /uint/i } @predicate, @errmsg ] );

    if ( Net::FastCGI::HAVE_XS ) {
        require Net::FastCGI::Util::XS;
        Net::FastCGI::Util::XS->import(@predicate);
    }
    else {
        require Net::FastCGI::Util::PP;
        Net::FastCGI::Util::PP->import(@predicate);
    }

    require Exporter;
    *import = \&Exporter::import;
}

sub ERRMSG_CVREF       () { q/Argument "%s" is not a CODE reference/                              }
sub ERRMSG_HVREF       () { q/Argument "%s" is not a HASH reference/                              }
sub ERRMSG_INSTANCE_OF () { q/Argument "%s" is not an instance of "%s"/                           }
sub ERRMSG_OCTETS_GE   () { q/Argument "%s" must be greater than or equal to %u octets in length/ }
sub ERRMSG_OCTETS_LE   () { q/Argument "%s" must be less than or equal to %u octets in length/    }
sub ERRMSG_OFFSET      () { q/Argument "%s" is outside of octets length/                          }
sub ERRMSG_UINT        () { q/Argument "%s" is not an unsigned integer/                           }
sub ERRMSG_UINT8       () { q/Argument "%s" is not an unsigned 8-bit integer/                     }
sub ERRMSG_UINT16      () { q/Argument "%s" is not an unsigned 16-bit integer/                    }
sub ERRMSG_UINT31      () { q/Argument "%s" is not an unsigned 31-bit integer/                    }
sub ERRMSG_UINT32      () { q/Argument "%s" is not an unsigned 32-bit integer/                    }
sub ERRMSG_VERSION     () { q/Unsupported FastCGI version: %u/                                    }

sub croakf {
    @_ = ( sprintf( $_[0], @_[ 1 .. $#_ ] ) ) if @_ > 1;
    goto \&croak;
}

sub carpf {
    @_ = ( sprintf( $_[0], @_[ 1 .. $#_ ] ) ) if @_ > 1;
    goto \&carp;
}

1;

