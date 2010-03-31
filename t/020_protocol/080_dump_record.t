#!perl

use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 28;
use Test::HexString;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[ :all ]);
    use_ok('Net::FastCGI::Protocol', qw[ :all ]);
}

my @types = (
    FCGI_BEGIN_REQUEST,
    FCGI_ABORT_REQUEST,
    FCGI_END_REQUEST,
    FCGI_PARAMS,
    FCGI_STDIN,
    FCGI_STDOUT,
    FCGI_STDERR,
    FCGI_DATA,
    FCGI_GET_VALUES,
    FCGI_GET_VALUES_RESULT,
    FCGI_UNKNOWN_TYPE,
    FCGI_MAXTYPE,
);

foreach my $type (@types) {
    like dump_record($type, 0), qr/\A\{ $FCGI_TYPE_NAME[$type] \, \s* 0/x;
}

foreach my $type (FCGI_PARAMS, FCGI_GET_VALUES, FCGI_GET_VALUES_RESULT) {
    my $name = $FCGI_TYPE_NAME[$type];
    {
        my $dump = dump_record($type, 1, '');
        like $dump, qr/\A \{ $FCGI_TYPE_NAME[$type]\, \s* 1\, \s* ""/x;
    }
    {
        my $dump = dump_record($type, 1, build_params({ '' => '' }));
        like $dump, qr/\A \{ $FCGI_TYPE_NAME[$type]\, \s* 1\, \s* "\\000\\000"/x;
    }
    {
        my $dump = dump_record($type, 1, build_params({ 'Foo' => '' }));
        like $dump, qr/\A \{ $FCGI_TYPE_NAME[$type]\, \s* 1\, \s* "\\003\\000Foo"/x;
    }
    {
        my $dump = dump_record($type, 1, build_params({ "Foo\r\n" => "\x01\x02" }));
        like $dump, qr/\A \{ $FCGI_TYPE_NAME[$type]\, \s* 1\, \s* "\\005\\002Foo\\r\\n\\x01\\x02/x;
    }
}

throws_ok { dump_record()               } qr/^Usage: /;
throws_ok { dump_record(0, 0, undef, 0) } qr/^Usage: /;

