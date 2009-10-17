#!perl

use bytes;
use strict;
use warnings;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 79;
use Test::BinaryData;
use Test::Exception;

BEGIN {
    use_ok('Net::FastCGI::Constant', qw[FCGI_NULL_REQUEST_ID]);
    use_ok('Net::FastCGI::Record::Values');
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        get_request_id
        get_values
        get_type
        has_content
        is_discrete
        is_management
        is_stream
        new
        parse
    ];

    can_ok( 'Net::FastCGI::Record::Values', @methods );
}

{
    my $record = Net::FastCGI::Record::Values->new( 0, {} );
    isa_ok( $record, 'Net::FastCGI::Record' );
    isa_ok( $record, 'Net::FastCGI::Record::Values' );
}

{
    my @tests = (
        # content                                            type   values
        [ "\x00\x00",                                          10,  { '' => '' },                     ],
        [ "\x01\x01\x31\x31",                                  10,  {  1 =>  1 },                     ],
        [ "\x01\x01\x41\x42\x01\x01\x43\x44\x01\x01\x45\x46",  10,  {  A => 'B', C => 'D', E => 'F' } ],
        [ "",                                                  10,  { }                               ],
    );

    my $record_test = sub ($$) {
        my ( $record, $test ) = @_;

        my $content_length = defined($test->[0]) ? length($test->[0]) : 0;
        my $has_content    = $content_length ? 'true' : 'false';

        is( $record->get_type,                      $test->[1], qq/get_type = FCGI_GET_VALUES_RESULT/    );
        is( $record->get_request_id,      FCGI_NULL_REQUEST_ID, qq/get_request_id = FCGI_NULL_REQUEST_ID/ );
        is( $record->get_content_length,       $content_length, qq/get_content_length = $content_length/  );
        is( $record->has_content,            !!$content_length, qq/has_content = $has_content/            );
        is( $record->is_stream,                            !!0, qq/is_stream = false/                     );
        is( $record->is_discrete,                          !!1, qq/is_discrete = true/                    );

        is_deeply( $record->get_values, $test->[2], q/get_values/ );

        if ( defined($test->[0]) ) {
            is_binary( $record->get_content, $test->[0], qq/get_content/ );
        }
        else {
            is( $record->get_content, $test->[0], qq/get_content/ )
        }
    };

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::Values->new( @$test[1..2] );
        $record_test->( $record, $test );
    }

    foreach my $test ( @tests ) {
        my $record = Net::FastCGI::Record::Values->parse( $test->[1], $test->[0] );
        $record_test->( $record, $test );
    }
}

throws_ok { Net::FastCGI::Record::Values->new              } qr/^Usage: /;
throws_ok { Net::FastCGI::Record::Values->new( -1, {} )    } qr/^Argument "type"/;
throws_ok { Net::FastCGI::Record::Values->new(  0, undef ) } qr/^Argument "values"/;
throws_ok { Net::FastCGI::Record::Values->parse            } qr/^Usage: /;

{
    my $values = {
        Foo => 'Bar' x 0xFFFF
    };

    throws_ok { Net::FastCGI::Record::Values->new( 0, $values ) } qr/^Argument "values" must be less than or equal to/;
}

{
    my @methods = qw[
        build
        get_content
        get_content_length
        has_content
        get_values
    ];

    my $record = Net::FastCGI::Record::Values->new( 0, {} );

    foreach my $method ( @methods ) {
        throws_ok { $record->$method(undef) } qr/^Usage: /;
    }
}

