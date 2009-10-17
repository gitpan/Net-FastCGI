package Net::FastCGI;

use strict;
use warnings;

BEGIN {
    our $VERSION = '0.01_01';

    if ( !$ENV{NET_FASTCGI_PP} ) {

        eval {
            require Net::FastCGI::XS;
        };
    }

    if ( $ENV{NET_FASTCGI_PP} || $@ ) {
        *HAVE_XS = sub () { !!0 };
    }
    else {
        *HAVE_XS = sub () { !!1 };
    }
}

1;

