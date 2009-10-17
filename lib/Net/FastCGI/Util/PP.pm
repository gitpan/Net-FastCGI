package Net::FastCGI::Util::PP;

use bytes;
use strict;
use warnings;

use Scalar::Util qw[blessed reftype];

BEGIN {
    our $VERSION     = 0.01;
    our @EXPORT_OK   = qw[ is_cvref
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

    our %EXPORT_TAGS = ( all => \@EXPORT_OK );

    *HAS_UTF8 = ( defined(&utf8::is_utf8) ) ? sub () { !!1 } : sub () { !!0 };

    require Exporter;
    *import = \&Exporter::import;
}

sub is_cvref ($) {
    return ( ref($_[0]) eq 'CODE' );
}

sub is_hvref ($) {
    return ( ref($_[0]) eq 'HASH' );
}

sub is_handle ($) {
    return ( ( ref($_[0]) ? reftype($_[0]) : reftype(\$_[0]) ) =~ /\A(?:GLOB|IO)\z/ );
}

sub is_object ($) {
    return defined( blessed($_[0]) );
}

sub is_instance_of ($$) {
    return ( &is_object && $_[0]->isa($_[1]) );
}

sub is_string ($) {
    return ( defined($_[0]) && ref(\$_[0]) eq 'SCALAR' );
}

sub is_octets ($) {
    if ( &is_string ) {

        if ( HAS_UTF8 && utf8::is_utf8($_[0]) ) {
            return utf8::downgrade( my $copy = $_[0], 1 );
        }
        return !!1;
    }
    return !!0;
}

sub is_octets_ge ($$) {
    return ( &is_octets && length($_[0]) >= $_[1] );
}

sub is_octets_le ($$) {
    return ( &is_octets && length($_[0]) <= $_[1] );
}

sub UINT8_MAX  () {       0xFF }
sub UINT16_MAX () {     0xFFFF }
sub UINT31_MAX () { 0x7FFFFFFF }
sub UINT32_MAX () { 0xFFFFFFFF }

sub is_uint ($) {
    return ( defined($_[0]) && $_[0] =~ /\A(?:0|[1-9][0-9]*)\z/ );
}

sub is_uint8 ($) {
    return ( &is_uint && $_[0] <= UINT8_MAX );
}

sub is_uint16 ($) {
    return ( &is_uint && $_[0] <= UINT16_MAX );
}

sub is_uint31 ($) {
    return ( &is_uint && $_[0] <= UINT31_MAX );
}

sub is_uint32 ($) {
    return ( &is_uint && $_[0] <= UINT32_MAX );
}

1;
