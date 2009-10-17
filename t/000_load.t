#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 15;

BEGIN {
    use_ok('Net::FastCGI');
    use_ok('Net::FastCGI::Constant');
    use_ok('Net::FastCGI::Header');
    use_ok('Net::FastCGI::Protocol');
    use_ok('Net::FastCGI::Record');
    use_ok('Net::FastCGI::Record::BeginRequest');
    use_ok('Net::FastCGI::Record::EndRequest');
    use_ok('Net::FastCGI::Record::Stream');
    use_ok('Net::FastCGI::Record::UnknownType');
    use_ok('Net::FastCGI::Record::Values');
    use_ok('Net::FastCGI::RecordFactory');
    use_ok('Net::FastCGI::Util');

    if ( $ENV{NET_FASTCGI_PP} ) {
        use_ok('Net::FastCGI::Protocol::PP');
        use_ok('Net::FastCGI::Util::PP');
    }
    else {
        use_ok('Net::FastCGI::Protocol::XS');
        use_ok('Net::FastCGI::Util::XS');
    }
}

if ( $ENV{NET_FASTCGI_PP} ) {
    is Net::FastCGI::HAVE_XS, !!0, 'Testing PP version';
}
else {
    is Net::FastCGI::HAVE_XS, !!1, 'Testing XS version';
}

diag("Net::FastCGI $Net::FastCGI::VERSION, Perl $], $^X");

