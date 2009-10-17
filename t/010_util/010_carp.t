#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 13;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Util', ':carp');
}

throws_ok {  croak('Foo Bar')        } qr/^Foo Bar/;
throws_ok {  croak('Foo ', 'Bar')    } qr/^Foo Bar/;
throws_ok { croakf('Foo %s/', 'Bar') } qr/^Foo Bar/;
throws_ok { croakf('Foo Bar')        } qr/^Foo Bar/;

sub carp_ok (&$$) {
    my ( $coderef, $expecting, $description ) = @_;

    my $got;
    lives_ok { local $SIG{__WARN__} = sub { $got = $_[0] }; &$coderef; } $description;
    like $got, $expecting, $description;
}

carp_ok { carp('Foo Bar')        } qr/^Foo Bar/, q/carp('Foo Bar')/;
carp_ok { carp('Foo ', 'Bar')    } qr/^Foo Bar/, q/carp('Foo ', 'Bar')/;
carp_ok { carpf('Foo %s', 'Bar') } qr/^Foo Bar/, q/carpf('Foo %s', 'Bar')/;
carp_ok { carpf('Foo Bar')       } qr/^Foo Bar/, q/carpf('Foo Bar')/;

